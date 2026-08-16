from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import pandas as pd

TRADING_DAYS = 252


@dataclass(frozen=True)
class BacktestResult:
    equity: pd.Series
    daily_returns: pd.Series
    weights: pd.DataFrame
    turnover: pd.Series
    metrics: dict[str, float | str]
    benchmark_equity: pd.Series


def _month_end_rows(index: pd.DatetimeIndex) -> pd.Series:
    periods = pd.Series(index.to_period("M"), index=index)
    return periods.ne(periods.shift(-1))


def _metrics(returns: pd.Series, equity: pd.Series) -> dict[str, float]:
    clean = returns.dropna()
    years = max(len(clean) / TRADING_DAYS, 1 / TRADING_DAYS)
    total_return = float(equity.iloc[-1] / equity.iloc[0] - 1)
    cagr = float((equity.iloc[-1] / equity.iloc[0]) ** (1 / years) - 1)
    volatility = float(clean.std(ddof=0) * np.sqrt(TRADING_DAYS))
    sharpe = float(clean.mean() / clean.std(ddof=0) * np.sqrt(TRADING_DAYS)) if volatility else 0.0
    drawdown = equity / equity.cummax() - 1
    return {
        "total_return": total_return,
        "cagr": cagr,
        "annual_volatility": volatility,
        "sharpe_zero_rf": sharpe,
        "max_drawdown": float(drawdown.min()),
    }


def run_trend_momentum(prices: pd.DataFrame, config: dict) -> BacktestResult:
    if prices.empty:
        raise ValueError("价格数据为空")
    prices = prices.sort_index().ffill().dropna(how="all")
    signal_cfg = config["signal"]
    portfolio_cfg = config["portfolio"]
    risk_cfg = config["risk"]

    trend_days = int(signal_cfg["trend_lookback_days"])
    momentum_days = int(signal_cfg["momentum_lookback_days"])
    top_n = int(signal_cfg["select_top_n"])
    max_weight = float(portfolio_cfg["max_position_weight"])

    trend_ok = prices > prices.rolling(trend_days, min_periods=trend_days).mean()
    momentum = prices.pct_change(momentum_days, fill_method=None)
    month_end = _month_end_rows(prices.index)

    target = pd.DataFrame(np.nan, index=prices.index, columns=prices.columns)
    for timestamp in prices.index[month_end]:
        eligible = momentum.loc[timestamp].where(trend_ok.loc[timestamp]).dropna()
        eligible = eligible[eligible > 0].nlargest(top_n)
        row = pd.Series(0.0, index=prices.columns)
        if not eligible.empty:
            weight = min(1.0 / len(eligible), max_weight)
            row.loc[eligible.index] = weight
        target.loc[timestamp] = row

    # The signal uses today's close and only becomes effective on the next trading day.
    effective_weights = target.ffill().shift(1).fillna(0.0)
    asset_returns = prices.pct_change(fill_method=None).fillna(0.0)
    gross_returns = (effective_weights * asset_returns).sum(axis=1)
    turnover = effective_weights.diff().abs().sum(axis=1).fillna(effective_weights.abs().sum(axis=1))
    cost_rate = (
        float(risk_cfg["assumed_commission_bps"]) + float(risk_cfg["assumed_slippage_bps"])
    ) / 10_000
    net_returns = gross_returns - turnover * cost_rate

    initial_cash = float(config["initial_cash_usd"])
    equity = initial_cash * (1 + net_returns).cumprod()
    benchmark = config["benchmark"]
    benchmark_returns = asset_returns[benchmark]
    benchmark_equity = initial_cash * (1 + benchmark_returns).cumprod()

    metrics: dict[str, float | str] = _metrics(net_returns, equity)
    benchmark_metrics = _metrics(benchmark_returns, benchmark_equity)
    metrics.update(
        {
            "strategy_id": str(config["strategy_id"]),
            "start": prices.index.min().date().isoformat(),
            "end": prices.index.max().date().isoformat(),
            "ending_value_usd": float(equity.iloc[-1]),
            "annual_turnover": float(turnover.mean() * TRADING_DAYS),
            "total_cost_usd_estimate": float((turnover * cost_rate * equity.shift(1).fillna(initial_cash)).sum()),
            "benchmark_total_return": benchmark_metrics["total_return"],
            "benchmark_cagr": benchmark_metrics["cagr"],
            "benchmark_max_drawdown": benchmark_metrics["max_drawdown"],
        }
    )
    return BacktestResult(equity, net_returns, effective_weights, turnover, metrics, benchmark_equity)

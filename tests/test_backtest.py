import numpy as np
import pandas as pd

from quant_lab.backtest import run_trend_momentum
from quant_lab.data import _parse_twelve_data


def _config():
    return {
        "strategy_id": "test",
        "initial_cash_usd": 100_000,
        "benchmark": "SPY",
        "signal": {"trend_lookback_days": 20, "momentum_lookback_days": 10, "select_top_n": 2},
        "portfolio": {"max_position_weight": 0.5},
        "risk": {"assumed_commission_bps": 1, "assumed_slippage_bps": 5},
    }


def test_long_only_and_exposure_limit():
    index = pd.bdate_range("2020-01-01", periods=180)
    prices = pd.DataFrame(
        {
            "SPY": 100 * np.cumprod(np.full(len(index), 1.001)),
            "QQQ": 100 * np.cumprod(np.full(len(index), 1.002)),
            "TLT": 100 * np.cumprod(np.full(len(index), 0.999)),
        },
        index=index,
    )
    result = run_trend_momentum(prices, _config())
    assert result.weights.min().min() >= 0
    assert result.weights.sum(axis=1).max() <= 1.0
    assert result.equity.iloc[-1] > 100_000


def test_future_price_change_does_not_change_prior_weights():
    index = pd.bdate_range("2020-01-01", periods=180)
    prices = pd.DataFrame({"SPY": np.linspace(100, 150, 180), "QQQ": np.linspace(100, 170, 180)}, index=index)
    original = run_trend_momentum(prices, _config()).weights
    changed = prices.copy()
    changed.iloc[-1] *= 10
    rerun = run_trend_momentum(changed, _config()).weights
    pd.testing.assert_frame_equal(original.iloc[:-1], rerun.iloc[:-1])


def test_parse_twelve_data_orders_dates_and_prices():
    payload = {
        "status": "ok",
        "values": [
            {"datetime": "2024-01-03", "close": "102.50"},
            {"datetime": "2024-01-02", "close": "100.00"},
        ],
    }
    series = _parse_twelve_data(payload, "SPY")
    assert list(series.index) == [pd.Timestamp("2024-01-02"), pd.Timestamp("2024-01-03")]
    assert list(series) == [100.0, 102.5]

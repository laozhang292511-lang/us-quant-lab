from __future__ import annotations

import os
from pathlib import Path
from urllib.parse import urlencode

import pandas as pd
import requests
import yfinance as yf


def _parse_twelve_data(payload: dict, symbol: str) -> pd.Series:
    if payload.get("status") == "error":
        message = payload.get("message", "未知错误")
        raise RuntimeError(f"Twelve Data 返回错误（{symbol}）：{message}")
    values = payload.get("values")
    if not isinstance(values, list) or not values:
        raise RuntimeError(f"Twelve Data 未返回 {symbol} 的日线数据")
    frame = pd.DataFrame(values)
    if "datetime" not in frame or "close" not in frame:
        raise RuntimeError(f"Twelve Data 的 {symbol} 数据缺少日期或收盘价")
    dates = pd.to_datetime(frame["datetime"], errors="coerce")
    closes = pd.to_numeric(frame["close"], errors="coerce")
    series = pd.Series(closes.to_numpy(), index=dates, name=symbol).dropna().sort_index()
    if series.empty:
        raise RuntimeError(f"Twelve Data 的 {symbol} 数据无法解析")
    return series[~series.index.duplicated(keep="last")]


def _download_twelve_data(
    symbols: list[str], start: str, end: str | None, api_key: str
) -> pd.DataFrame:
    series: dict[str, pd.Series] = {}
    endpoint = "https://api.twelvedata.com/time_series"
    for symbol in symbols:
        params = {
            "symbol": symbol,
            "interval": "1day",
            "start_date": start,
            "outputsize": 5000,
            "adjust": "all",
            "format": "JSON",
            "apikey": api_key,
        }
        if end:
            params["end_date"] = end
        response = requests.get(endpoint, params=params, timeout=45)
        response.raise_for_status()
        series[symbol] = _parse_twelve_data(response.json(), symbol)
    return pd.DataFrame(series).sort_index().ffill().dropna(how="any")


def _download_stooq(symbols: list[str], start: str, end: str | None) -> pd.DataFrame:
    start_compact = start.replace("-", "")
    end_compact = end.replace("-", "") if end else pd.Timestamp.today().strftime("%Y%m%d")
    series: dict[str, pd.Series] = {}
    for symbol in symbols:
        query = urlencode(
            {"s": f"{symbol.lower()}.us", "d1": start_compact, "d2": end_compact, "i": "d"}
        )
        frame = pd.read_csv(f"https://stooq.com/q/d/l/?{query}")
        if frame.empty or "Date" not in frame or "Close" not in frame:
            raise RuntimeError(f"Stooq 未返回 {symbol} 的有效数据")
        frame["Date"] = pd.to_datetime(frame["Date"])
        series[symbol] = frame.set_index("Date")["Close"].sort_index()
    return pd.DataFrame(series).sort_index().ffill().dropna(how="any")


def download_adjusted_prices(
    symbols: list[str], start: str, end: str | None, cache_path: str | Path
) -> pd.DataFrame:
    cache = Path(cache_path)
    cache.parent.mkdir(parents=True, exist_ok=True)
    twelve_data_key = os.environ.get("TWELVE_DATA_API_KEY", "").strip()
    if twelve_data_key:
        close = _download_twelve_data(symbols, start, end, twelve_data_key)
        if close.empty or close.isna().all().any():
            raise RuntimeError("Twelve Data 未返回完整行情；没有生成回测。")
        close.to_csv(cache, index_label="date")
        return close

    frame = yf.download(
        symbols,
        start=start,
        end=end,
        auto_adjust=True,
        actions=False,
        progress=False,
        group_by="column",
        threads=True,
    )
    if frame.empty:
        try:
            close = _download_stooq(symbols, start, end)
        except Exception as exc:
            raise RuntimeError(
                "Yahoo Finance 当前限流，Stooq 也未能返回公开 CSV；没有生成回测。"
            ) from exc
    else:
        close = frame["Close"] if isinstance(frame.columns, pd.MultiIndex) else frame[["Close"]]
        if not isinstance(close, pd.DataFrame):
            close = close.to_frame(name=symbols[0])
        close = close.reindex(columns=symbols).dropna(how="all")
    if close.empty or close.isna().all().any():
        raise RuntimeError("免费行情源未返回完整数据。请检查网络或稍后重试。")
    close.to_csv(cache, index_label="date")
    return close


def load_cached_prices(cache_path: str | Path) -> pd.DataFrame:
    return pd.read_csv(cache_path, index_col="date", parse_dates=True)

from __future__ import annotations

import argparse
from pathlib import Path

from .backtest import run_trend_momentum
from .config import load_config
from .data import download_adjusted_prices, load_cached_prices
from .report import write_report


def main() -> None:
    parser = argparse.ArgumentParser(description="美股 ETF 确定性回测")
    parser.add_argument("--config", default="config/strategy-etf-daily.yaml")
    parser.add_argument("--start", default="2010-01-01")
    parser.add_argument("--end", default=None)
    parser.add_argument("--offline", action="store_true", help="仅使用本地缓存")
    args = parser.parse_args()

    root = Path.cwd()
    config = load_config(root / args.config)
    cache = root / "data" / "market" / "etf-daily-adjusted.csv"
    try:
        if args.offline:
            prices = load_cached_prices(cache)
        else:
            prices = download_adjusted_prices(config["universe"], args.start, args.end, cache)
    except (RuntimeError, FileNotFoundError) as exc:
        parser.exit(2, f"回测未运行：{exc}\n")
    result = run_trend_momentum(prices, config)
    report_path = write_report(result, root / "reports" / "backtests")
    print(f"回测完成: {report_path}")
    print(f"期末资产: ${result.metrics['ending_value_usd']:,.2f}")
    print(f"年化收益: {result.metrics['cagr']:.2%}")
    print(f"最大回撤: {result.metrics['max_drawdown']:.2%}")


if __name__ == "__main__":
    main()

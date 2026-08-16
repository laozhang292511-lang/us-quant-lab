from __future__ import annotations

import json
from pathlib import Path

from .backtest import BacktestResult

PERCENT_KEYS = {
    "total_return",
    "cagr",
    "annual_volatility",
    "max_drawdown",
    "annual_turnover",
    "benchmark_total_return",
    "benchmark_cagr",
    "benchmark_max_drawdown",
}


def write_report(result: BacktestResult, output_dir: str | Path) -> Path:
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    stamp = result.metrics["end"]
    stem = f"{result.metrics['strategy_id']}-{stamp}"

    result.equity.rename("strategy_equity").to_csv(output / f"{stem}-equity.csv", index_label="date")
    result.weights.to_csv(output / f"{stem}-weights.csv", index_label="date")
    with (output / f"{stem}-metrics.json").open("w", encoding="utf-8") as handle:
        json.dump(result.metrics, handle, ensure_ascii=False, indent=2)

    lines = [
        f"# 回测报告：{result.metrics['strategy_id']}",
        "",
        f"期间：{result.metrics['start']} 至 {result.metrics['end']}",
        "",
        "| 指标 | 结果 |",
        "|---|---:|",
    ]
    labels = {
        "ending_value_usd": "期末资产（美元）",
        "total_return": "策略总收益",
        "cagr": "策略年化收益",
        "annual_volatility": "年化波动",
        "sharpe_zero_rf": "夏普比率（无风险利率=0）",
        "max_drawdown": "最大回撤",
        "annual_turnover": "年化换手",
        "total_cost_usd_estimate": "估算交易成本（美元）",
        "benchmark_total_return": "基准总收益",
        "benchmark_cagr": "基准年化收益",
        "benchmark_max_drawdown": "基准最大回撤",
    }
    for key, label in labels.items():
        value = result.metrics[key]
        rendered = f"{float(value):.2%}" if key in PERCENT_KEYS else f"{float(value):,.3f}"
        lines.append(f"| {label} | {rendered} |")
    lines.extend(
        [
            "",
            "> 本报告仅用于研究与模拟，不构成投资建议。免费数据可能修订或缺失，正式实盘前必须使用独立数据复核。",
            "",
        ]
    )
    report_path = output / f"{stem}.md"
    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path

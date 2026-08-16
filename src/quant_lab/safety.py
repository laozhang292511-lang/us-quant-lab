from __future__ import annotations

import os
from dataclasses import dataclass
from enum import StrEnum


class TradingMode(StrEnum):
    BACKTEST = "backtest"
    SIMULATION = "simulation"
    LIVE = "live"


@dataclass(frozen=True)
class SafetyDecision:
    allowed: bool
    reasons: tuple[str, ...]


def evaluate_execution_safety(
    system_config: dict,
    requested_mode: str,
    *,
    central_lock_held: bool = False,
    environment: dict[str, str] | None = None,
) -> SafetyDecision:
    env = environment if environment is not None else dict(os.environ)
    reasons: list[str] = []
    try:
        mode = TradingMode(requested_mode)
    except ValueError:
        return SafetyDecision(False, (f"未知运行模式: {requested_mode}",))

    if mode is not TradingMode.LIVE:
        return SafetyDecision(True, ())

    security = system_config.get("security", {})
    components = system_config.get("components", {})
    if not security.get("allow_broker_credentials", False):
        reasons.append("此电脑配置禁止保存或使用券商凭据")
    if not components.get("schwab_live", False):
        reasons.append("嘉信实盘组件未启用")
    if env.get("LIVE_TRADING_ENABLED", "false").lower() != "true":
        reasons.append("LIVE_TRADING_ENABLED 未显式设为 true")
    if security.get("require_single_executor_lock", True) and not central_lock_held:
        reasons.append("未取得中央单执行器锁")

    required = ("SCHWAB_API_KEY", "SCHWAB_APP_SECRET", "SCHWAB_CALLBACK_URL", "SCHWAB_TOKEN_PATH")
    missing = [name for name in required if not env.get(name)]
    if missing:
        reasons.append("缺少嘉信凭据变量: " + ", ".join(missing))
    return SafetyDecision(not reasons, tuple(reasons))

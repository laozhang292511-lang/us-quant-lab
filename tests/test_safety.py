from quant_lab.safety import evaluate_execution_safety


def _config(*, credentials: bool, schwab_live: bool):
    return {
        "components": {"schwab_live": schwab_live},
        "security": {
            "allow_broker_credentials": credentials,
            "require_single_executor_lock": True,
        },
    }


def _live_env():
    return {
        "LIVE_TRADING_ENABLED": "true",
        "SCHWAB_API_KEY": "test",
        "SCHWAB_APP_SECRET": "test",
        "SCHWAB_CALLBACK_URL": "https://127.0.0.1",
        "SCHWAB_TOKEN_PATH": "test-token.json",
    }


def test_backtest_and_simulation_are_allowed_without_credentials():
    config = _config(credentials=False, schwab_live=False)
    assert evaluate_execution_safety(config, "backtest", environment={}).allowed
    assert evaluate_execution_safety(config, "simulation", environment={}).allowed


def test_computer_b_cannot_go_live_even_if_credentials_are_present():
    config = _config(credentials=False, schwab_live=True)
    decision = evaluate_execution_safety(
        config, "live", central_lock_held=True, environment=_live_env()
    )
    assert not decision.allowed
    assert any("禁止" in reason for reason in decision.reasons)


def test_live_requires_all_independent_gates():
    config = _config(credentials=True, schwab_live=True)
    assert evaluate_execution_safety(
        config, "live", central_lock_held=True, environment=_live_env()
    ).allowed
    assert not evaluate_execution_safety(
        config, "live", central_lock_held=False, environment=_live_env()
    ).allowed

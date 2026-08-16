# Quant Lab repository instructions

This repository is the reproducible master for the user's US equity research system.

## Safety boundaries

- Treat `config/local.yaml` as the machine profile. If its profile is `computer-b-restricted`, never enable live trading or store broker credentials, OAuth tokens, full account exports, or private account reports on that machine.
- Never commit `.env`, API keys, tokens, `data/`, `runtime/`, `envs/`, `.tools/`, `vendor/`, or private reports.
- Bind local dashboards to `127.0.0.1`; do not expose them to the LAN or internet.
- Keep live trading disabled unless the user separately authorizes a reviewed live-execution phase. Computer B is never an authorized live executor.
- Do not change versions in `config/components.lock.yaml` without explaining the upgrade and receiving user approval.

## Installation and verification

- Install large dependencies inside the repository's chosen non-system drive.
- On a new Windows computer, run `scripts/Setup-Computer.ps1 -Profile ComputerB` (or `ComputerA` on a personal research machine).
- Run `scripts/Test-All.ps1` after installation and `scripts/Export-EnvironmentFingerprint.ps1` to record the verified environment.
- A deployment is complete only when all automated tests pass and locked component versions match.

## Daily workflow

- Use `scripts/Run-Backtest.ps1 -Offline` for cached-data research.
- Use `scripts/Export-SharedReport.ps1` to copy only a reviewed, non-private report into `reports/shared/` before Git synchronization.
- Research and simulation may run on multiple machines, but future broker execution must have exactly one explicitly authorized executor.

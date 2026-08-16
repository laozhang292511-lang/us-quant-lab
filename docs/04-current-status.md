# 当前搭建状态

更新日期：2026-08-16

## 已完成

- D 盘隔离 Python 3.11.13 与 uv 0.8.12
- 本地确定性 ETF 趋势/动量回测核心
- Vibe-Trading 0.1.13
- Lumibot 4.5.83 与 Schwab 适配器（未配置凭据）
- AgentQuant 0.2.0，固定源码提交 `8275a8e5331bd63b5a7bcb26e9704ecca85c2bc2`
- 9 个项目级交易研究/风控技能
- A/B 多电脑安全配置、实盘安全门和一键入口
- 母版核心测试与 AgentQuant 63 项测试

## 尚未完成

- 第一次真实 ETF 历史回测：Yahoo 被限流，Stooq 触发浏览器验证；未使用不完整数据
- Vibe-Trading 的 LLM 登录：需用户选择 OAuth/模型后操作
- GitHub 私有仓库创建与两机同步：需用户决定仓库名并登录 GitHub
- 本地 Git 仓库已初始化；尚未提交，因为本机没有配置 Git 提交姓名/邮箱
- Windows 管理员安全检查：Defender、防火墙、BitLocker、更新和内存信息
- Schwab Developer Portal 应用：留到模拟交易稳定后，不应现在填写凭据
- Docker/WSL：首阶段原生 Windows 已可运行，暂不增加复杂度

## 当前可运行

- `scripts\Test-All.ps1`：全套离线验收
- `scripts\Start-Vibe.ps1`：本机 Vibe-Trading 网页界面
- `scripts\Start-AgentQuant.ps1`：本机 AgentQuant 仪表板
- `scripts\Run-Backtest.ps1`：下载行情并运行首个策略；免费数据源受限时会安全停止

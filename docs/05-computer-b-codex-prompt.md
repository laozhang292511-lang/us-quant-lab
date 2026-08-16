# 给电脑 B 上 Codex 的交接提示词

将下列整段内容发给电脑 B 的 Codex。把 `<安装目录>` 替换为单位允许使用、且你选择的非系统盘目录。

```text
请为我部署“美股量化交易母版”的电脑 B 受限配置。

背景：
- 这是单位电脑，功能要包含研究、回测、模拟交易、报告阅读和未来扩展能力。
- 严禁在本机保存或使用 Charles Schwab 券商凭据、OAuth 令牌、完整账户流水；严禁真实下单。
- 安装根目录是：<安装目录>。大型软件、Python、环境、缓存和数据都放这里，不要默认放 C 盘。
- 母版来自我的 GitHub 私有仓库；先让我登录 GitHub，再克隆仓库。

必须执行：
1. 先只读检查 Windows、CPU、内存、磁盘、Git、网络、Defender、防火墙和磁盘加密；涉及管理员权限或单位策略时先停下说明。
2. 阅读仓库 README、docs、config/computer-b.example.yaml 和 config/components.lock.yaml。
3. 将 computer-b.example.yaml 复制为本机配置，填写所选安装目录，保持：
   - allow_broker_credentials: false
   - schwab_live: false
   - mode: backtest
4. 不要自行猜测安装命令。运行 `scripts/Setup-Computer.ps1 -Profile ComputerB -ConfirmUnitPolicy`，由母版安装锁定的 Python 3.11 和独立环境；所有缓存留在安装目录。
5. 不创建 .env 中的任何券商字段，不导入账户数据，不开启公网监听。网页服务只能绑定 127.0.0.1。
6. 安装器结束后再次运行 `scripts/Test-All.ps1` 与 `scripts/Export-EnvironmentFingerprint.ps1 -Verify`；只有全部通过才报告完成。
7. 检查 Git 同步内容不含密钥、令牌、data、runtime、envs、.tools、vendor 或私人报告。
8. 最终告诉我：安装位置、版本、空间占用、测试结果、未完成项和日常一键入口。

如果仓库指令与以上安全边界冲突，以以上安全边界为准。不要申请或配置实盘权限。
```

## 交接前提

- 先在电脑 A 创建 GitHub 私有仓库并推送母版。
- 电脑 B 只使用细粒度、最小权限的 GitHub 授权；优先使用系统凭据管理器，不把令牌写入文件。
- 若单位制度不允许个人代码、金融数据、代理软件或开发环境，停止部署并遵守单位制度。
- 具体点击、命令、验收与故障处理见 `docs/07-computer-b-step-by-step.md`。

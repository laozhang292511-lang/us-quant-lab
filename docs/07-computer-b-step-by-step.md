# 电脑 B 部署手册（单位电脑受限配置）

适用情形：电脑 B 已安装 Codex，但尚未搭建量化环境。按顺序执行，不要跳步。

## 一、今天提前准备

记录以下三项，明天带到电脑 B：

1. 私有仓库：`https://github.com/laozhang292511-lang/us-quant-lab.git`
2. GitHub 用户名：`laozhang292511-lang`
3. 计划安装目录，例如 `D:\US-Quant-Lab` 或 `E:\US-Quant-Lab`

不要记录或携带电脑 A 的 Twelve Data API Key、嘉信密码、令牌或加密密钥文件。

预计需要：约 6–8 GB 可用空间、稳定网络、通常 20–60 分钟。首次下载时 GitHub 和 Python 包源必须可访问。

## 二、开始前的单位制度检查

先确认单位允许：

- 安装个人开发环境；
- 登录私人 GitHub；
- 保存公开市场研究代码和公开行情；
- 使用单位网络访问 GitHub/Python 包源。

只要其中一项不确定，就先询问单位管理员，不要绕过安全软件、网络限制或管理员策略。

## 三、检查磁盘并选择目录

1. 打开“此电脑”。
2. 选择单位允许使用、空间充足的非系统盘，例如 D 盘或 E 盘。
3. 记下最终目录，例如 `D:\US-Quant-Lab`。
4. 不要把 `envs`、`.tools`、`vendor` 单独放进 OneDrive、网盘或 Git。

如果电脑只有 C 盘，先停止，让电脑 B 的 Codex 检查空间和单位规定；不要擅自使用 `-AllowSystemDrive`。

## 四、确认 Git 和仓库访问

1. 在浏览器打开 `https://github.com`，登录自己的 GitHub。
2. 确认能看到私有仓库 `us-quant-lab`。
3. 打开普通 PowerShell，不要使用“以管理员身份运行”。
4. 输入：

```powershell
git --version
```

如果显示版本号，继续。若提示找不到 Git，把错误原文交给电脑 B 的 Codex，让它在单位政策允许范围内安装 Git；不要从不明网站下载。

## 五、克隆母版

下面以 `D:\US-Quant-Lab` 为例；如果选的是 E 盘，必须把命令中的路径全部换成 E 盘。

```powershell
git clone https://github.com/laozhang292511-lang/us-quant-lab.git "D:\US-Quant-Lab"
Set-Location "D:\US-Quant-Lab"
git status
```

首次克隆可能弹出 GitHub 浏览器登录或 Windows 凭据管理器授权。只在 GitHub 官方页面登录，不要把密码、验证码或令牌粘贴给 Codex。

成功标志：`git status` 显示位于 `main` 分支，没有错误。

## 六、让电脑 B 的 Codex接管

1. 打开电脑 B 的 Codex。
2. 打开本地文件夹 `D:\US-Quant-Lab`（按实际盘符替换）。
3. 新建任务，把下面整段文字粘贴给 Codex：

```text
请按照本仓库 AGENTS.md 和 docs/07-computer-b-step-by-step.md 部署电脑 B。
这是单位电脑，只允许研究、回测、模拟和报告功能；严禁保存嘉信凭据、OAuth 令牌、完整账户数据，严禁真实下单。
安装目录就是当前仓库目录。先做只读预检，不要修改单位安全设置；确认仓库位于获准的非系统盘后，运行：
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Setup-Computer.ps1 -Profile ComputerB -ConfirmUnitPolicy
安装结束后运行完整验收和环境指纹验证。任何管理员权限、单位策略、C 盘安装、密钥要求或测试失败都必须停止并告诉我，不能绕过。
```

Codex 会先检查环境，再请求你批准联网下载。允许前确认命令指向本仓库和官方 GitHub/Python 包源。

## 七、安装与等待

安装器会自动完成：

- 在当前盘的 `.tools` 安装 uv 0.8.12 和 Python 3.11.13；
- 在 `envs` 创建 core、vibe、lumibot、agentquant 四套隔离环境；
- 固定 Vibe-Trading 0.1.13、Lumibot 4.5.83；
- 从固定提交安装 AgentQuant 0.2.0；
- 写入受限本机配置 `config/local.yaml`；
- 保持 `schwab_live: false` 和 `allow_broker_credentials: false`；
- 自动运行全部测试与环境指纹验证。

下载期间不要关机。日常可以使用电脑，但安装时会占用网络、磁盘和部分 CPU。

## 八、判断是否成功

必须同时满足：

1. Windows PowerShell 5.1 兼容性预检通过；
2. 核心测试显示 6 项通过；
3. AgentQuant 显示 63 项通过；
4. Vibe-Trading 显示 0.1.13；
5. Lumibot 显示 4.5.83；
6. `runtime/environment-fingerprint.json` 中：
   - `profile` 是 `computer-b-restricted`；
   - `verification_passed` 是 `true`；
   - `failures` 是空列表；
7. Codex确认没有把密钥、`data`、`runtime`、`envs`、`.tools`、`vendor` 提交到 Git。

把最终验收结果或截图发回电脑 A 的这个任务复核。测试失败不代表可以“先用起来”，必须先解决。

## 九、电脑 B 的行情选择

基础部署不复制 A 的行情和密钥。电脑 B 可以立即阅读 `reports/shared` 的脱敏报告并运行全部离线软件测试。

如果需要在 B 独立下载新行情，满足单位制度后，建议注册一个与券商无关、无付费权限、可随时撤销的独立 Twelve Data Key，再在 B 本机运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Set-TwelveDataKey.ps1
```

不要复制 A 的 `runtime/secrets/twelve-data.key`：DPAPI 本来也无法在 B 解密。电脑 B 永远不配置嘉信凭据。

## 十、以后在 A/B 之间切换

开始工作前，在仓库目录运行：

```powershell
git pull --ff-only
```

结束工作后，让 Codex检查变更，只提交代码、配置模板、文档和 `reports/shared` 中确认脱敏的报告，再推送 GitHub。不要在两台电脑上同时修改同一个文件；先完成一台的提交和推送，再切换另一台。

以下内容永远不通过 Git 同步：

- `config/local.yaml`
- `.env` 和所有密钥
- `data` 行情缓存
- `runtime` 日志、锁和环境指纹
- `envs`、`.tools`、`vendor`
- 完整账户数据和私人报告

## 十一、必须停止并求助的情况

- 要求管理员权限或关闭 Defender、防火墙、磁盘加密；
- 安装目标意外变成 C 盘；
- Codex或脚本索要嘉信密码、令牌或账户文件；
- GitHub 登录页面域名可疑；
- 任一自动测试失败；
- Git 准备上传密钥、行情、运行目录或账户数据；
- 单位安全软件发出告警。

此时保存错误文字或截图，回到电脑 A 的 Codex任务中询问，不要自行绕过。

## 十二、电脑归还、更换或遗失

立即执行：

1. 在 GitHub 撤销该设备的会话或凭据；
2. 如果 B 配置过独立 Twelve Data Key，立即在 Twelve Data 撤销；
3. 通知单位 IT；
4. 不需要修改嘉信凭据，因为 B 从未保存嘉信凭据；
5. 新电脑重新从私有仓库安装，不复制旧电脑的 `runtime` 或密钥。

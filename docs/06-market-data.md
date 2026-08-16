# 行情数据配置

## 首选：Twelve Data

首阶段使用 Twelve Data Basic Free，通过 `/time_series` 获取日线：

- 每个代码 1 credit，8 只 ETF 共 8 credits
- `outputsize=5000`
- `adjust=all`，包含拆股和分红调整
- API Key 不进入代码、聊天或 Git

## 安全录入

运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Set-TwelveDataKey.ps1
```

密钥保存为 `runtime/secrets/twelve-data.key`。内容使用 Windows DPAPI 加密，只能由录入时的 Windows 用户在本机解密。复制到电脑 B 后不能解密，也不应该把 A 的数据密钥复制到单位电脑。

## 数据源顺序

1. 已配置 Twelve Data Key：优先使用 Twelve Data。
2. 未配置 Key：尝试 Yahoo Finance。
3. Yahoo 不可用：尝试 Stooq。
4. 所有来源均失败或任一标的缺失：停止，不生成回测。

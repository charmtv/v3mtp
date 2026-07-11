# Telemt

基于 Rust + Tokio 的高性能 Telegram MTProto 代理。

## 安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/charmtv/v3mtp/main/install.sh)
```

管理菜单支持安装、检查更新、查看链接、服务管理、日志、配置和卸载。更新包会自动校验，启动失败时回滚旧版本。

支持 `x86_64`、`aarch64`，兼容 GNU 和 musl Linux。

## 特性

- 支持经典、安全和 TLS 模式
- TLS 伪装与重放攻击防护
- Middle-End 连接池与 IPv6
- 配置热重载和优雅关闭

## 常用命令

```bash
systemctl status telemt
systemctl restart telemt
journalctl -u telemt -n 50 --no-pager
```

配置文件：`/etc/telemt.toml`

## 最小配置

```toml
[general]
use_middle_proxy = false

[general.modes]
tls = true

[censorship]
tls_domain = "www.tesla.com"

[server]
port = 443

[[server.listeners]]
ip = "0.0.0.0"

[access.users]
user1 = "00000000000000000000000000000000"
```

## Docker

```bash
docker compose up -d --build
docker compose logs -f telemt
```

## 文档

- [快速开始](docs/QUICK_START_GUIDE.md)
- [常见问题](docs/FAQ.md)
- [性能调优](docs/TUNING.md)
- [Xray / sing-box 路由](docs/XRAY-SINGBOX-ROUTING.md)

## 构建

```bash
cargo build --release
```

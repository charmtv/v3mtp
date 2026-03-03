# Telemt

基于 Rust + Tokio 的高性能 Telegram MTProto 代理

## 一键安装

```bash
bash <(wget -qO- https://raw.githubusercontent.com/charmtv/v3mtp/main/install.sh)
```

安装脚本提供交互式菜单，支持安装、更新、查看链接、服务管理、修改配置、卸载等功能。

## 功能特性

- 完整支持 MTProto 代理协议（经典/安全/TLS 模式）
- TLS 伪装：未授权连接透明转发到真实网站
- 重放攻击防护
- Middle-End 连接池，高吞吐量
- 可配置心跳保活、超时、IPv6
- 优雅关闭

## 手动安装

```bash
# 下载
wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz

# 安装
mv telemt /usr/local/bin && chmod +x /usr/local/bin/telemt
```

## 最小配置

`/etc/telemt.toml`:

```toml
[general]
[general.modes]
classic = false
secure = false
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

## Systemd 服务

```bash
# 启动
systemctl start telemt

# 状态
systemctl status telemt

# 开机自启
systemctl enable telemt

# 获取链接
journalctl -u telemt -n -g "links" --no-pager -o cat | tac
```

## Docker

```bash
# Docker Compose
docker compose up -d --build

# 查看日志
docker compose logs -f telemt
```

## 编译构建

```bash
git clone https://github.com/charmtv/v3mtp
cd v3mtp
cargo build --release
mv ./target/release/telemt /usr/local/bin
chmod +x /usr/local/bin/telemt
```

## 常见问题

**打开文件过多**：在 systemd 服务中添加 `LimitNOFILE=65536`

**DPI 识别**：TLS 模式下流量与真实 HTTPS 一致，包含有效的信任链和熵值

**Telegram 通话**：MTProxy 不支持通话，仅 SOCKS5 支持

# 通过 Systemd 使用 Telemt

## 安装

本软件设计用于基于 Debian 的操作系统：除 Debian 外，还包括 Ubuntu、Mint、Kali、MX 等

### 一键安装（推荐）
```bash
bash <(wget -qO- https://raw.githubusercontent.com/charmtv/v3mtp/main/install.sh)
```

### 手动安装

**1. 下载**
```bash
wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz
```
**2. 移动到系统目录**
```bash
mv telemt /usr/local/bin
```
**3. 设置执行权限**
```bash
chmod +x /usr/local/bin/telemt
```

## 如何使用？

**本教程假设您：**
- 已以 root 身份登录或已执行 `su -` / `sudo su`
- 已经拥有可执行的 telemt 文件在 /usr/local/bin 目录中。请阅读 **[安装](#安装)** 章节。

---

**0. 检查端口并生成密钥**

您选择使用的端口不应出现在以下列表中：
```bash
netstat -lnp
```

使用 OpenSSL 生成 16 字节/32 字符的 HEX 密钥：
```bash
openssl rand -hex 16
```
或者
```bash
xxd -l 16 -p /dev/urandom
```
或者
```bash
python3 -c 'import os; print(os.urandom(16).hex())'
```
保存获得的结果，稍后会用到！

---

**1. 将配置放置到 /etc/telemt.toml**

打开编辑器
```bash
nano /etc/telemt.toml
```
粘贴配置内容

```toml
# === 基本设置 ===
[general]
# ad_tag = "00000000000000000000000000000000"

[general.modes]
classic = false
secure = false
tls = true

# === 反审查 & 伪装 ===
[censorship]
tls_domain = "www.google.com"

[access.users]
# 格式: "用户名" = "32位HEX密钥"
hello = "00000000000000000000000000000000"
```
然后按 Ctrl+S -> Ctrl+X 保存

> [!WARNING]
> 将 hello 参数的值替换为步骤 0 中生成的密钥。
> 将 tls_domain 参数的值替换为其他网站域名。

---

**2. 在 /etc/systemd/system/telemt.service 创建服务**

打开编辑器
```bash
nano /etc/systemd/system/telemt.service
```

粘贴以下 Systemd 服务配置
```bash
[Unit]
Description=Telemt
After=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/telemt /etc/telemt.toml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```
然后按 Ctrl+S -> Ctrl+X 保存


**3.** 启动服务：`systemctl start telemt`

**4.** 查看状态：`systemctl status telemt`

**5.** 设置开机自启：`systemctl enable telemt`

**6.** 获取连接链接：`journalctl -u telemt -n -g "links" --no-pager -o cat | tac`

---

# 通过 Docker Compose 使用 Telemt

**1. 编辑仓库根目录的 `config.toml`（至少设置：端口、用户密钥、tls_domain）**
**2. 启动容器：**
```bash
docker compose up -d --build
```
**3. 查看日志：**
```bash
docker compose logs -f telemt
```
**4. 停止：**
```bash
docker compose down
```
> [!NOTE]
> - `docker-compose.yml` 将 `./config.toml` 映射到 `/app/config.toml`（只读）
> - 默认发布 `443:443` 端口并以降权方式运行（仅添加 `NET_BIND_SERVICE` 权限）
> - 如果确实需要主机网络模式（通常仅用于某些 IPv6 设置），请取消注释 `network_mode: host`

**不使用 Compose 运行**
```bash
docker build -t telemt:local .
docker run --name telemt --restart unless-stopped \
  -p 443:443 \
  -e RUST_LOG=info \
  -v "$PWD/config.toml:/app/config.toml:ro" \
  --read-only \
  --cap-drop ALL --cap-add NET_BIND_SERVICE \
  --ulimit nofile=65536:65536 \
  telemt:local
```

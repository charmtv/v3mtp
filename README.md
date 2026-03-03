# Telemt - 基于 Rust + Tokio 的 MTProxy 代理

***在问题出现之前就解决它们***

**Telemt** 是一个用 Rust 编写的快速、安全且功能丰富的 Telegram 代理服务器：它完整实现了官方 Telegram 代理协议，并增加了许多生产级改进，如连接池、重放攻击防护、详细统计、流量伪装等。

[**Telemt Telegram 交流群**](https://t.me/telemtrs)

## 最新消息

### ✈️ Telemt 3 正式发布！

#### 版本 3.0.15 — 2月25日发布

2月25日，我们发布了版本 **3.0.15**

我们预计这将成为 3.0 系列的最终版本，目前我们已将其视为即将发布的 **3.1.0** 版本的强力 **LTS 候选版本**！

经过数天对 Middle-End 行为的深入分析，我们设计并实现了精心设计的 **ME Writer 轮换模式**。该模式能够在长时间运行场景中保持持续高吞吐量，同时防止代理配置错误。

我们期待您的反馈和改进建议——特别是关于 **统计** 和 **用户体验** 方面。

最新版本：
[3.0.15](https://github.com/charmtv/v3mtp/releases/tag/3.0.15)

---

如果您在以下领域有专长：

- 异步网络应用
- 流量分析
- 逆向工程
- 网络取证

我们欢迎您的想法、架构反馈和 Pull Requests。

# 功能特性

💥 自版本 1.1.0.0 起配置结构已更改，请在您的环境中更新配置！

⚓ 我们的 **TLS 伪装** 实现是最深入调试、最专注、最先进且 *几乎* **"行为一致于真实"** 的实现之一：我们有信心做到了——[查看我们的验证和追踪证据](#dpi-和爬虫的可识别性)

⚓ 我们的 ***Middle-End 连接池*** 在标准场景下的设计速度最快，与其他 Middle-End 代理连接实现相比。

# 目录

- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [如何使用？](#如何使用)
  - [Systemd 方式](#通过-systemd-使用-telemt)
- [配置说明](#配置说明)
  - [最小配置](#首次启动最小配置)
  - [高级配置](#高级配置)
    - [广告标签](#广告标签)
    - [监听和公告 IP](#监听和公告-ip)
    - [上游管理](#上游管理)
      - [绑定 IP](#绑定-ip)
      - [SOCKS 代理](#socks45-上游代理)
- [常见问题](#常见问题)
  - [DPI 和爬虫的可识别性](#dpi-和爬虫的可识别性)
  - [Telegram 通话](#通过-mtproxy-进行-telegram-通话)
  - [DPI 如何识别](#dpi-如何看待-mtproxy-tls)
  - [IP 白名单](#ip-白名单)
  - [打开文件过多](#打开文件过多)
- [编译构建](#编译构建)
- [Docker](#docker)
- [为什么选择 Rust？](#为什么选择-rust)

## 功能特性

- 完整支持所有官方 MTProto 代理模式：
  - 经典模式
  - 安全模式 - 带 `dd` 前缀
  - 伪装 TLS 模式 - 带 `ee` 前缀 + SNI 前端伪装
- 重放攻击防护
- 可选流量伪装：将未识别的连接转发到真实网站，如 GitHub 🤪
- 可配置的心跳保活 + 超时 + IPv6 和"快速模式"
- Ctrl+C 优雅关闭
- 通过 `trace` 和 `debug` 以及 `RUST_LOG` 方法进行详细日志记录

## 快速开始

**本软件设计用于基于 Debian 的操作系统：除 Debian 外，还包括 Ubuntu、Mint、Kali、MX 等众多 Linux 发行版**

### 一键安装（推荐）

```bash
bash <(wget -qO- https://raw.githubusercontent.com/charmtv/v3mtp/main/install.sh)
```

### 手动安装

1. 下载最新版本
```bash
wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz
```
2. 移动到系统目录
```bash
mv telemt /usr/local/bin
```
3. 设置执行权限
```bash
chmod +x /usr/local/bin/telemt
```
4. 继续查看 [如何使用？](#如何使用) 章节完成配置

## 如何使用？

### 通过 Systemd 使用 Telemt

**本教程假设您：**
- 已以 root 身份登录或已执行 `su -` / `sudo su`
- 您已经通过 [快速开始](#快速开始) 或 [编译构建](#编译构建) 获得了可执行的 `telemt` 文件

**0. 检查端口并生成密钥**

您选择使用的端口不应出现在以下列表中：
```bash
netstat -lnp
```

使用 OpenSSL 或其他方式生成 16 字节/32 字符的 HEX 密钥：
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

**1. 将配置文件放置到 /etc/telemt.toml**

打开编辑器
```bash
nano /etc/telemt.toml
```
粘贴 [配置说明](#配置说明) 章节中的配置内容

然后按 Ctrl+X -> Y -> Enter 保存

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
然后按 Ctrl+X -> Y -> Enter 保存

**3.** 在终端输入 `systemctl start telemt` — 服务应以零退出码启动

**4.** 在终端输入 `systemctl status telemt` — 可以查看当前 MTProxy 状态信息

**5.** 在终端输入 `systemctl enable telemt` — 设置开机自启动，在网络就绪后启动

**6.** 在终端输入 `journalctl -u telemt -n -g "links" --no-pager -o cat | tac` — 获取连接链接

## 配置说明

### 首次启动最小配置
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

### 高级配置

#### 广告标签
要使用 Telegram 的频道广告和使用统计功能，请从 [@mtproxybot](https://t.me/mtproxybot) 获取广告标签。在 `[access.user_ad_tags]` 中为每个用户设置（32位HEX字符）：
```toml
[access.user_ad_tags]
用户名1 = "11111111111111111111111111111111"  # 替换为从 @mtproxybot 获取的标签
用户名2 = "22222222222222222222222222222222"
```

#### 监听和公告 IP
要指定监听地址和/或链接中的地址，在 config.toml 的 `[[server.listeners]]` 部分添加：
```toml
[[server.listeners]]
ip = "0.0.0.0"          # 0.0.0.0 = 所有IP; 填写你的IP = 指定监听
announce_ip = "1.2.3.4" # 链接中的IP; 不使用请用 # 注释掉
```

#### 上游管理
要指定上游连接方式，在 config.toml 的 `[[upstreams]]` 部分添加：

##### 绑定 IP
```toml
[[upstreams]]
type = "direct"
weight = 1
enabled = true
interface = "192.168.1.100" # 更改为你的出站IP
```

##### SOCKS4/5 上游代理
- 无认证：
```toml
[[upstreams]]
type = "socks5"            # 指定 SOCKS4 或 SOCKS5
address = "1.2.3.4:1234"   # SOCKS 服务器地址
weight = 1                 # 设置负载权重
enabled = true
```

- 需要认证：
```toml
[[upstreams]]
type = "socks5"            # 指定 SOCKS4 或 SOCKS5
address = "1.2.3.4:1234"   # SOCKS 服务器地址
username = "user"          # SOCKS 服务器用户名
password = "pass"          # SOCKS 服务器密码
weight = 1                 # 设置负载权重
enabled = true
```

## 常见问题

### DPI 和爬虫的可识别性
自版本 1.1.0.0 起，我们已完美调试了伪装功能：对于所有没有"出示"密钥的客户端，
我们透明地将流量定向到目标主机！

- 我们认为这是一个突破性功能，目前没有稳定的替代品
- 基于此：如果 `telemt` 配置正确，**TLS 模式与真实的握手 + 通信完全一致**
- 以下是我们的证据：
    - 212.220.88.77 - "测试"主机，运行 `telemt`
    - `petrovich.ru` - `tls` + `masking` 主机，HEX: `706574726f766963682e7275`
    - **无 MITM + 无伪造证书/密码学** = 纯粹透明的 *TCP Splice* 到"最佳"上游：MTProxy 或 tls/mask-host：
      - DPI 看到的是合法的 HTTPS 到 `tls_host`，包括 *有效的信任链* 和熵值
      - 爬虫完全满意地接收来自 `mask_host` 的响应

  #### 有密钥的客户端访问 MTProxy 资源：
  
  <img width="360" height="439" alt="telemt" src="https://github.com/user-attachments/assets/39352afb-4a11-4ecc-9d91-9e8cfb20607d" />
  
  #### 没有密钥的客户端透明访问指定资源：
    - 使用可信证书
    - 使用原始握手
    - 完整的请求-响应流程
    - 低延迟开销

### 通过 MTProxy 进行 Telegram 通话
- Telegram 架构 **不允许通过 MTProxy 进行通话**，只支持通过 SOCKS5，而 SOCKS5 无法进行混淆

### DPI 如何看待 MTProxy TLS？
- DPI 将伪装 TLS (ee) 模式的 MTProxy 视为 TLS 1.3
- 您指定的 SNI 会同时发送到客户端和服务器
- ALPN 类似于 HTTP 1.1/2
- 高熵值，这对于 AES 加密流量来说是正常的

### IP 白名单
- MTProxy 在以下情况下无法工作：
  - 没有到目标主机的 IP 连通性：俄罗斯移动网络白名单
  - 或所有 TCP 流量被阻断
  - 或高熵值/加密流量被阻断：大学和关键基础设施的内容过滤器
  - 或所有 TLS 流量被阻断
  - 或指定端口被阻断：使用 443 端口使其"像真实流量"
  - 或指定的 SNI 被阻断：使用"官方批准"/无害的域名
- 与互联网上大多数协议类似
- 以下地区可能遇到此问题：
  - 中国（大陆防火墙后）
  - 俄罗斯移动网络（有线网络较少）
  - 伊朗（"活动"期间）

### 打开文件过多
- 在新安装的 Linux 上，默认打开文件数限制较低；高负载时 `telemt` 可能出现 `Accept error: Too many open files` 错误
- **Systemd**：在 `[Service]` 部分添加 `LimitNOFILE=65536`（上面的示例中已包含）
- **Docker**：在 `docker run` 命令中添加 `--ulimit nofile=65536:65536`，或在 `docker-compose.yml` 中：
```yaml
ulimits:
  nofile:
    soft: 65536
    hard: 65536
```
- **系统级别**（可选）：添加到 `/etc/security/limits.conf`：
```
*       soft    nofile  1048576
*       hard    nofile  1048576
root    soft    nofile  1048576
root    hard    nofile  1048576
```

## 编译构建
```bash
# 克隆仓库
git clone https://github.com/charmtv/v3mtp
# 进入目录
cd v3mtp
# 开始 Release 构建
cargo build --release
# 移动到系统目录
mv ./target/release/telemt /usr/local/bin
# 设置执行权限
chmod +x /usr/local/bin/telemt
# 开始运行！
telemt config.toml
```

## Docker

**快速开始（Docker Compose）**

1. 编辑仓库根目录的 `config.toml`（至少设置：端口、用户密钥、tls_domain）
2. 启动容器：
```bash
docker compose up -d --build
```
3. 查看日志：
```bash
docker compose logs -f telemt
```
4. 停止：
```bash
docker compose down
```

**说明**
- `docker-compose.yml` 将 `./config.toml` 映射到 `/app/config.toml`（只读）
- 默认发布 `443:443` 端口并以降权方式运行（仅添加 `NET_BIND_SERVICE` 权限）
- 如果确实需要主机网络模式（通常仅用于某些 IPv6 设置），请取消注释 `network_mode: host`

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

## 为什么选择 Rust？
- 长期运行的可靠性和幂等行为
- Rust 的确定性资源管理 - RAII
- 无垃圾回收器
- 内存安全和减少攻击面
- Tokio 的异步架构

## 已解决的问题
- ✅ [SOCKS5 作为上游](https://github.com/charmtv/v3mtp/issues/1) -> 已添加上游管理
- ✅ [iOS - 媒体上传循环卡住](https://github.com/charmtv/v3mtp/issues/2)

## 路线图
- 链接中的公网 IP
- 运行时配置重载
- 出站/入站连接绑定到设备或 IP
- 每个 SNI / 密钥的广告标签支持
- 启动时快速失败 + 运行时软失败（仅 WARN/ERROR）
- 零拷贝，热路径最小分配
- DC 健康检查 + 全局回退
- 无全局可变状态
- 客户端隔离 + 公平带宽
- 背压感知 IO
- "密钥策略" - SNI / 密钥路由 :D
- 多上游负载均衡和故障转移
- 严格的每次握手状态机
- 基于会话的滑动窗口防重放，不中断重连
- Web 控制面板：统计、健康状态、延迟、客户端体验...

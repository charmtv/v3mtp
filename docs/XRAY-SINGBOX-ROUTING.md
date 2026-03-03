# xray-core / sing-box 中的 SNI 路由 + TLS 前端伪装

## 术语说明

- **TLS 前端伪装域名** — 在 TLS ClientHello 中作为 **SNI** 出现的域名（例如 `www.google.com`）：它在 L7 层用作"掩护"，也是代理路由器中的路由键。
- **xray-core / sing-box** — 本地或远程 L7/TLS 路由器（代理），它：
  1) 接受入站 TCP/TLS 连接
  2) 读取 TLS ClientHello
  3) 提取 SNI
  4) 根据 SNI 选择 outbound/上游
  5) 从自身发起新的 TCP 连接到目标主机
- **SNI (Server Name Indication)** — TLS ClientHello 中的字段，Telegram 客户端在此通告用于"伪装"的域名
- **L7 路由器侧的 DNS 解析** — 如果出站地址是域名，DNS 在 **xray/sing-box 侧**解析，而非 Telegram 客户端侧

---

## 核心概念：连接实际去向不是由您告诉客户端的决定，而是由 L7 路由器如何解析 SNI 决定

机制：

1) 您可以给 Telegram 客户端指定 **telemt 的 IP/域名**作为"服务器"
2) 在客户端和 telemt 之间，xray-core/sing-box 接收 TCP，读取 TLS ClientHello 并看到 **SNI=www.google.com**
3) 路由器说："看到 SNI - 转发到上游/路由 N"
4) 并建立出站连接，不是"到用户预期的 IP"，而是**到 SNI 中的域名**
5) 如果该域名的 A 记录 **不指向 telemt 的 IP**，流量将被导向该域名的"原始"网站

---

## 问题场景

```text
Telegram 客户端
   |
   | TLS ClientHello: SNI=www.google.com
   v
xray-core / sing-box
   |
   | 根据 SNI 路由 -> DNS 解析 www.google.com
   | -> 连接到 Google 的真实 IP
   v
Google 真实服务器（不是 telemt）
   |
   X  不是 telemt -> Telegram 无法正常连接
```

---

## 正确方案：使用自有域名 + 指向 telemt + Let's Encrypt 证书

### 目标

- SNI（前端伪装域名）的 DNS **解析到 telemt 的 IP**
- telemt IP 上有使用该域名的有效 TLS 证书
- 即使有人尝试通过浏览器访问该域名，也能看到正常的网页

### 优势

- xray/sing-box 根据 SNI 路由时，必定会到达 telemt
- 外观合理：普通域名配普通证书
- 稳定性好：不受 DNS 缓存/重新解析的影响

---

## 推荐架构

```text
Telegram 客户端
   |
   | TLS ClientHello: SNI = hello.example.com
   v
xray-core / sing-box
   |
   | 根据 SNI 路由 -> 连接到 hello.example.com:443
   | DNS(hello.example.com) = telemt 的 IP
   v
telemt 实例（telemt IP）
   |
   | hello.example.com 的 TLS 证书（Let's Encrypt）
   | + 网站占位页面
   v
成功！
```

---

## 实施清单

1. 拥有一个域名：`hello.example.com`
2. DNS 设置：
   - `A hello.example.com -> <telemt IP>`
   - （可选）如使用 IPv6 则添加 AAAA 记录
3. 在 telemt 主机上：
   - 在 443 端口部署使用 Let's Encrypt 证书的 TLS 端点
   - 提供一个"占位页面"使域名看起来像正常网站
4. 在 xray/sing-box 规则中：
   - 根据 SNI = `hello.example.com` 路由到 telemt 的 outbound
   - 避免 destination override 将流量导向其他域名
5. 注意：
   - 如路由器使用 DNS 缓存，更改 A 记录后需刷新/更新

---

## 关于 TLS 前端伪装页面的说明

telemt 的 TLS-F 子系统（位于 `src/tls_front`）：
- fetcher 模块收集 TLS 配置文件，以最大程度模拟指定网站的 TLS 行为

当您指定一个无法通过 TLS 响应的网站时：
- fetcher 无法收集 TLS 配置文件，回退到 `fake_cert_len` — 原始算法
- 它用随机字节填充 TLS 服务信息
- 简单的 DPI 系统无法识别
- 但高级系统（如 nEdge 或移动网络中的欺诈控制）可以轻松阻止或减慢此类流量

创建带有 Let's Encrypt 证书的占位网站，可以让 TLS-F 获取证书数据并正确"复制"它

---

## 可能意外破坏"正确" DNS 的因素

- **DNS 缓存** — xray/sing-box 或系统解析器上的缓存，特别是在更改 A 记录时
- **IPv6** — 如果有 AAAA 记录指向错误位置，路由器可能优先使用 IPv6
- **DoH/DoT** — 路由器可能使用不同于您测试时的解析器

最佳实践：
- 控制 A/AAAA 记录
- 保持合理的 TTL
- 检查路由器实际使用哪个解析器
- 必要时禁用/限制 destination override

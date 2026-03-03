### 3.0.0 Anschluss
- **Middle Proxy 现已稳定**，已在约 20 位用户的金丝雀部署中确认
- 广告标签现已工作
- DC=203/CDN 现已通过 ME 工作
- `getProxyConfig` 和 `ProxySecret` 已自动化
- 版本号现在采用 `3.0.0` 格式 — 不再使用 Windows 风格的"微修复"

### 3.0.1 Kabelsammler
- 修复了握手超时问题
- 重构了连接日志
- Docker：为 ProxyConfig 和 ProxySecret 使用 tmpfs
- 配置中支持公共主机和端口
- 修复了 ME Relay 的队头阻塞问题
- ME 心跳检测

### 3.0.2 Microtrencher
- 新增 [network] 配置部分
- ME 修复
- 小 bug 修复

### 3.0.3 Ausrutscher
- ME 作为有状态模式，无连接 ID 迁移
- RpcWriter 后数据路径上不再 `flush()`
- 使用高性能解析器处理 IPv6（不使用正则表达式）
- `nat_probe = true` 设为默认值
- STUN 客户端 `recv()` 添加超时
- ConnRegistry 代码审查
- 双栈紧急重连

### 3.0.4 Schneeflecken
- Normal 日志级别仅显示 WARN 和链接
- 一致的 IP 协议族检测
- 配置文件支持 include
- `nonce_frame_hex` 仅在 `DEBUG` 级别记录

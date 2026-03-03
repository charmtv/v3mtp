# Middle-End 代理

## KDF 寻址 — 实现常见问题

### C 语言参考实现是否需要外部 IP 地址和端口用于 KDF？

**是的！**

在 C 语言参考实现中，**IP 地址和端口都包含在连接双方的 KDF 输入中**。

在 `aes_create_keys()` 中，KDF 输入明确包含：

- `server_ip + client_port`
- `client_ip + server_port`
- 后跟共享密钥/随机数

对于 IPv6：

- IPv4 字段置零
- 插入 IPv6 地址

但是，**无论 IP 版本如何，client_port 和 server_port 始终是 KDF 的一部分**。

> 如果外部观察到的 IP 或端口（例如由于 NAT、SOCKS 或代理穿越）与对端期望的不同，派生的密钥将不匹配，握手将失败。

---

### 可以从 KDF 中排除端口吗（例如使用 port = 0）？

**不可以！**

C 语言实现 **没有提供忽略端口的机制**：

- `client_port` 和 `server_port` 明确包含在 KDF 输入中
- 始终传递真实的套接字端口：
  - `c->our_port`
  - `c->remote_port`

如果端口为 `0`，它仍然作为 `0` 被纳入 KDF。

**没有条件逻辑来排除端口**。

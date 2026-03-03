# 常见问题

## 如何设置"代理赞助频道"

1. 打开 Telegram 机器人 @MTProxybot
2. 输入命令 `/newproxy`
3. 发送服务器的 IP 和端口。例如：1.2.3.4:443
4. 打开配置文件 `nano /etc/telemt.toml`
5. 复制 [access.users] 中的用户密钥并发送给机器人
6. 复制机器人返回的 tag。例如：1234567890abcdef1234567890abcdef
7. 取消注释 ad_tag 参数并填入机器人返回的 tag
8. 取消注释/添加参数 use_middle_proxy = true

配置示例：
```toml
[general]
ad_tag = "1234567890abcdef1234567890abcdef"
use_middle_proxy = true
```
9.  保存配置。Ctrl+S -> Ctrl+X
10. 重启 telemt：`systemctl restart telemt`
11. 在机器人中发送 /myproxies 并选择已添加的服务器
12. 点击 "Set promotion" 按钮
13. 发送频道的**公开链接**。不能添加私有频道！
14. 等待约 1 小时，让信息在 Telegram 服务器上更新

> [!WARNING]
> 如果您已经订阅了该频道，则不会显示"代理赞助"

## 一个链接可以供多少人使用

默认情况下，一个链接可以供任意数量的人使用。
您可以限制使用代理的 IP 数量。
```toml
[access.user_max_unique_ips]
hello = 1
```
此参数限制同一时间内有多少个唯一 IP 可以使用一个链接。如果一个用户断开连接，另一个用户就可以连接。同一 IP 可以有多个用户。

## 如何创建多个不同的链接

1. 生成所需数量的密钥：`openssl rand -hex 16`
2. 打开配置文件：`nano /etc/telemt.toml`
3. 添加新用户：
```toml
[access.users]
user1 = "00000000000000000000000000000001"
user2 = "00000000000000000000000000000002"
user3 = "00000000000000000000000000000003"
```
4. 保存配置。Ctrl+S -> Ctrl+X。无需重启 telemt。
5. 通过以下命令获取链接：`journalctl -u telemt -n -g "links" --no-pager -o cat | tac`

## 如何查看指标

1. 打开配置文件：`nano /etc/telemt.toml`
2. 添加以下参数：
```toml
[server]
metrics_port = 9090
metrics_whitelist = ["127.0.0.1/32", "::1/128", "0.0.0.0/0"]
```
3. 保存配置。Ctrl+S -> Ctrl+X
4. 指标可通过 SERVER_IP:9090/metrics 访问

> [!WARNING]
> metrics_whitelist 中的 "0.0.0.0/0" 允许任何 IP 访问。请替换为您的 IP，例如 "1.2.3.4"

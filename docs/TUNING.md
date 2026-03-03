# Telemt 调优指南：Middle-End 和上游

本文档描述了 Middle-End (ME) 和上游路由的当前运行时行为，基于：
- `src/config/types.rs`
- `src/config/defaults.rs`
- `src/config/load.rs`
- `src/transport/upstream.rs`

以下默认值为代码默认值（省略键时使用），不一定是 `config.full.toml` 示例中的值。

## Middle-End 参数

### 1) 核心 ME 模式、NAT 和 STUN

| 参数 | 类型 | 默认值 | 约束/验证 | 运行时效果 | 示例 |
|---|---|---:|---|---|---|
| `general.use_middle_proxy` | `bool` | `true` | 无 | 启用 ME 传输模式。为 `false` 时使用直连模式。 | `use_middle_proxy = true` |
| `general.proxy_secret_path` | `Option<String>` | `"proxy-secret"` | 路径可为 `null` | Telegram 基础设施 proxy-secret 文件路径。 | `proxy_secret_path = "proxy-secret"` |
| `general.middle_proxy_nat_ip` | `Option<IpAddr>` | `null` | 设置时须为有效 IP | 手动覆盖用于 ME 地址材料的公网 NAT IP。 | `middle_proxy_nat_ip = "203.0.113.10"` |
| `general.middle_proxy_nat_probe` | `bool` | `true` | `use_middle_proxy=true` 时自动强制为 `true` | 启用 ME NAT 探测。 | `middle_proxy_nat_probe = true` |
| `general.stun_nat_probe_concurrency` | `usize` | `8` | 必须 `> 0` | NAT 发现期间最大并行 STUN 探测数。 | `stun_nat_probe_concurrency = 16` |
| `network.stun_use` | `bool` | `true` | 无 | 全局 STUN 开关。为 `false` 时禁用 STUN 探测。 | `stun_use = true` |
| `network.stun_servers` | `Vec<String>` | 内置公共池 | 去重 + 移除空值 | NAT/公共端点发现的主要 STUN 服务器列表。 | `stun_servers = ["stun1.l.google.com:19302"]` |
| `network.stun_tcp_fallback` | `bool` | `true` | 无 | UDP STUN 被阻止时启用 TCP 回退路径。 | `stun_tcp_fallback = true` |
| `network.http_ip_detect_urls` | `Vec<String>` | `ifconfig.me` + `api.ipify.org` | 无 | STUN 不可用时用于公网 IPv4 检测的 HTTP 回退。 | `http_ip_detect_urls = ["https://api.ipify.org"]` |
| `timeouts.me_one_retry` | `u8` | `12` | 无 | 单端点 DC 情况下的快速重连尝试次数。 | `me_one_retry = 6` |
| `timeouts.me_one_timeout_ms` | `u64` | `1200` | 无 | 每次快速单端点尝试的超时时间（毫秒）。 | `me_one_timeout_ms = 1500` |

### 2) 连接池大小、心跳保活和重连策略

| 参数 | 类型 | 默认值 | 约束/验证 | 运行时效果 | 示例 |
|---|---|---:|---|---|---|
| `general.middle_proxy_pool_size` | `usize` | `8` | 无 | 目标活跃 ME writer 池大小。 | `middle_proxy_pool_size = 12` |
| `general.me_keepalive_enabled` | `bool` | `true` | 无 | 启用周期性 ME 心跳/ping 流量。 | `me_keepalive_enabled = true` |
| `general.me_keepalive_interval_secs` | `u64` | `25` | 无 | 基础心跳间隔（秒）。 | `me_keepalive_interval_secs = 20` |
| `general.me_keepalive_jitter_secs` | `u64` | `5` | 无 | 心跳抖动以避免同步突发。 | `me_keepalive_jitter_secs = 3` |
| `general.me_keepalive_payload_random` | `bool` | `true` | 无 | 随机化心跳载荷字节。 | `me_keepalive_payload_random = true` |
| `general.me_warmup_stagger_enabled` | `bool` | `true` | 无 | 错开额外 ME 预热拨号以避免峰值。 | `me_warmup_stagger_enabled = true` |
| `general.me_warmup_step_delay_ms` | `u64` | `500` | 无 | 预热拨号步骤之间的基础延迟（毫秒）。 | `me_warmup_step_delay_ms = 300` |
| `general.me_warmup_step_jitter_ms` | `u64` | `300` | 无 | 预热步骤的额外随机延迟（毫秒）。 | `me_warmup_step_jitter_ms = 200` |
| `general.me_reconnect_max_concurrent_per_dc` | `u32` | `8` | 无 | 限制每个 DC 的并发重连工作线程数。 | `me_reconnect_max_concurrent_per_dc = 12` |
| `general.me_reconnect_backoff_base_ms` | `u64` | `500` | 无 | 初始重连退避时间（毫秒）。 | `me_reconnect_backoff_base_ms = 250` |
| `general.me_reconnect_backoff_cap_ms` | `u64` | `30000` | 无 | 最大重连退避时间（毫秒）。 | `me_reconnect_backoff_cap_ms = 10000` |
| `general.me_reconnect_fast_retry_count` | `u32` | `16` | 无 | 长退避行为前的即时重试预算。 | `me_reconnect_fast_retry_count = 8` |

### 3) 重初始化/硬切换、密钥轮换和降级

| 参数 | 类型 | 默认值 | 约束/验证 | 运行时效果 | 示例 |
|---|---|---:|---|---|---|
| `general.hardswap` | `bool` | `true` | 无 | 启用基于代的 ME 硬切换策略。 | `hardswap = true` |
| `general.me_reinit_every_secs` | `u64` | `900` | 必须 `> 0` | 周期性 ME 重初始化间隔。 | `me_reinit_every_secs = 600` |
| `general.me_config_stable_snapshots` | `u8` | `2` | 必须 `> 0` | 应用前需要的相同 ME 配置快照数。 | `me_config_stable_snapshots = 3` |
| `general.me_config_apply_cooldown_secs` | `u64` | `300` | 无 | 应用 ME 映射更新之间的冷却时间。 | `me_config_apply_cooldown_secs = 120` |
| `general.proxy_secret_rotate_runtime` | `bool` | `true` | 无 | 启用运行时 proxy-secret 轮换。 | `proxy_secret_rotate_runtime = true` |
| `general.update_every` | `Option<u64>` | `300` | 如设置则必须 `> 0` | ME 配置 + 密钥更新器的统一刷新间隔。 | `update_every = 300` |
| `general.me_pool_drain_ttl_secs` | `u64` | `90` | 无 | 旧 writer 保持回退可用的时间窗口。 | `me_pool_drain_ttl_secs = 120` |
| `general.me_pool_min_fresh_ratio` | `f32` | `0.8` | 必须在 `[0.0,1.0]` 之间 | 旧代可被排空前的覆盖率阈值。 | `me_pool_min_fresh_ratio = 0.9` |
| `general.auto_degradation_enabled` | `bool` | `true` | 无 | 自动降级标志。 | `auto_degradation_enabled = true` |

## 上游配置

### 上游模式

| 字段 | 适用于 | 类型 | 必需 | 默认值 | 含义 |
|---|---|---|---|---|---|
| `type` | 所有上游 | `"direct" \| "socks4" \| "socks5"` | 是 | 无 | 上游传输类型。 |
| `weight` | 所有上游 | `u16` | 否 | `1` | 加权随机选择的基础权重。 |
| `enabled` | 所有上游 | `bool` | 否 | `true` | 禁用的条目在启动时被忽略。 |
| `interface` | `direct` | `Option<String>` | 否 | `null` | 绑定选择的接口名称或本地 IP。 |
| `address` | `socks4/5` | `String` | 是 | 无 | SOCKS 服务器端点。 |
| `username` | `socks5` | `Option<String>` | 否 | `null` | SOCKS5 用户名认证。 |
| `password` | `socks5` | `Option<String>` | 否 | `null` | SOCKS5 密码认证。 |

### 运行时规则

1. 如果省略 `[[upstreams]]`，加载器会注入一个默认的 `direct` 上游。
2. 健康的上游通过加权随机选择：`weight * latency_factor`。
3. 如果过滤集中没有健康的上游，则在过滤条目中使用随机选择。
4. 在 ME 模式下，选择的上游也用于 ME TCP 拨号路径。

### 配置示例

#### 示例 1：最小直连上游
```toml
[[upstreams]]
type = "direct"
weight = 1
enabled = true
```

#### 示例 2：带接口绑定的直连
```toml
[[upstreams]]
type = "direct"
interface = "eth0"
bind_addresses = ["192.168.1.100"]
weight = 3
enabled = true
```

#### 示例 3：带认证的 SOCKS5 上游
```toml
[[upstreams]]
type = "socks5"
address = "198.51.100.30:1080"
username = "proxy-user"
password = "proxy-pass"
weight = 2
enabled = true
```

#### 示例 4：ME 优化配置
```toml
[general]
use_middle_proxy = true
proxy_secret_path = "proxy-secret"
middle_proxy_nat_probe = true
middle_proxy_pool_size = 12
me_keepalive_enabled = true
me_keepalive_interval_secs = 20
hardswap = true
me_reinit_every_secs = 600
update_every = 300

[timeouts]
me_one_retry = 8
me_one_timeout_ms = 1200

[network]
stun_use = true
stun_tcp_fallback = true
stun_servers = [
  "stun1.l.google.com:19302",
  "stun2.l.google.com:19302"
]
```

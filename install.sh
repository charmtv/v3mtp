#!/bin/bash
# Telemt v3 - https://mtp.813099.xyz
B='' DIM='' RED='' GREEN='' YELLOW='' CYAN='' NC=''
if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
    B='\033[1m'; DIM='\033[2m'; RED='\033[31m'; GREEN='\033[32m'
    YELLOW='\033[33m'; CYAN='\033[36m'; NC='\033[0m'
fi
CF=/etc/telemt.toml BP=/usr/local/bin/telemt
SF=/etc/systemd/system/telemt.service GH=https://github.com/charmtv/v3mtp
banner() {
    clear
    echo -e "\n${CYAN}${B}  +---------------------------------------------+"
    echo -e "  |           Telemt v3 管理工具               |\n  |      高性能 Telegram MTProto 代理          |"
    echo -e "  +---------------------------------------------+${NC}\n"
}
line() { echo -e "  ${DIM}---------------------------------------------${NC}"; }
ok()   { echo -e "  ${GREEN}${B}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}${B}[!]${NC} $1"; }
err()  { echo -e "  ${RED}${B}[X]${NC} $1"; }
info() { echo -e "  ${CYAN}${B}[i]${NC} $1"; }
get_version() { [ -x "$BP" ] && "$BP" --version 2>/dev/null | awk '{print $2}' || echo "-"; }
get_latest_version() {
    local json
    if command -v curl >/dev/null 2>&1; then
        json=$(curl -fsSL --max-time 8 -H 'Accept: application/vnd.github+json' https://api.github.com/repos/charmtv/v3mtp/releases/latest 2>/dev/null)
    elif command -v wget >/dev/null 2>&1; then
        json=$(wget -qO- --timeout=8 https://api.github.com/repos/charmtv/v3mtp/releases/latest 2>/dev/null)
    fi
    printf '%s' "$json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}
get_port() { sed -n 's/^[[:space:]]*port[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$CF" 2>/dev/null | head -1; }
fetch_file() {
    local url="$1" output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --connect-timeout 10 --retry 2 --progress-bar -o "$output" "$url"
    else wget -O "$output" "$url"; fi
}
release_asset() {
    local ar lc
    case "$(uname -m)" in
        x86_64|amd64) ar=x86_64 ;;
        aarch64|arm64) ar=aarch64 ;;
        *) return 1 ;;
    esac
    lc=gnu; ldd --version 2>&1 | grep -iq musl && lc=musl
    echo "telemt-${ar}-linux-${lc}"
}
download_release() {
    local dir="$1" asset
    asset=$(release_asset) || {
        err "不支持的系统架构: $(uname -m)"
        return 1
    }
    info "下载最新版本: $asset"
    fetch_file "$GH/releases/latest/download/${asset}.tar.gz" "$dir/${asset}.tar.gz" || return 1
    fetch_file "$GH/releases/latest/download/${asset}.sha256" "$dir/${asset}.sha256" || return 1
    if ! (cd "$dir" && sha256sum -c "${asset}.sha256" >/dev/null 2>&1); then
        err "SHA-256 校验失败"
        return 1
    fi
    tar -xzf "$dir/${asset}.tar.gz" -C "$dir" || return 1
    [ -f "$dir/telemt" ] || return 1
    chmod +x "$dir/telemt"
    "$dir/telemt" --version >/dev/null 2>&1 || return 1
    ok "下载与校验完成"
}
check_dependencies() {
    local cmd missing=""
    for cmd in openssl od tar sha256sum systemctl install awk sed grep mktemp ldd; do
        command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
    done
    command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || missing="$missing curl/wget"
    [ -z "$missing" ] && return 0
    err "缺少依赖:$missing"
    return 1
}
valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; }
valid_domain() { [[ "$1" =~ ^[A-Za-z0-9.-]+$ ]] && [[ "$1" == *.* ]]; }
valid_user() { [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]; }
get_ip() {
    local i url
    for url in https://api.ipify.org https://ifconfig.me https://icanhazip.com; do
        if command -v curl >/dev/null 2>&1; then
            i=$(curl -4 -fsS --max-time 5 "$url" 2>/dev/null)
        else i=$(wget -4 -qO- --timeout=5 "$url" 2>/dev/null); fi
        [ -n "$i" ] && break
    done
    echo "$i" | tr -d ' \n\r'
}
rnd_port() {
    echo $(( RANDOM % 62000 + 1024 ))
}
chk() {
    [ -f "$BP" ] && systemctl list-unit-files 2>/dev/null | grep -q telemt
}
status() {
    if chk; then
        if systemctl is-active --quiet telemt 2>/dev/null; then
            echo -e "${GREEN}${B}运行中${NC}"
        else
            echo -e "${YELLOW}${B}已停止${NC}"
        fi
    else
        echo -e "${DIM}未安装${NC}"
    fi
}
links() {
    local ip="$1" pt="$2" us="$3" sc="$4" dm="$5"
    if [ -z "$ip" ]; then
        ip=$(get_ip)
        [ -z "$ip" ] && ip=YOUR_IP
    fi
    if [ -z "$pt" ]; then
        # Links advertise public_port when set, otherwise the [server] listen port.
        pt=$(sed -n 's/^[[:space:]]*public_port[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$CF" 2>/dev/null | head -1)
        [ -z "$pt" ] && pt=$(get_port)
        [ -z "$pt" ] && pt=443
    fi
    if [ -z "$sc" ]; then
        local ln
        ln=$(awk '/^\[access\.users\]/{users=1;next} /^\[/{users=0} users && /= "/{print;exit}' "$CF" 2>/dev/null)
        us=$(echo "$ln" | cut -d= -f1 | tr -d ' ')
        sc=$(echo "$ln" | cut -d'"' -f2)
    fi
    if [ -z "$dm" ]; then
        dm=$(sed -n 's/^[[:space:]]*tls_domain[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$CF" 2>/dev/null | head -1)
        [ -z "$dm" ] && dm=www.tesla.com
    fi
    local hd
    hd=$(printf '%s' "$dm" | od -An -tx1 | tr -d ' \n')
    local fs="ee${sc}${hd}"
    echo -e "  ${B}--- 连接信息 ---${NC}"
    echo ""
    echo -e "  ${B}  服务器:    $ip${NC}"
    echo -e "  ${B}  端口:      $pt${NC}"
    echo -e "  ${B}  用户名:    $us${NC}"
    echo -e "  ${B}  密钥:      $sc${NC}"
    echo -e "  ${B}  伪装域名:  $dm${NC}"
    echo ""
    echo -e "  ${B}--- Telegram 链接 ---${NC}"
    echo ""
    echo -e "  ${B}tg://proxy?server=${ip}&port=${pt}&secret=${fs}${NC}"
    echo ""
    echo -e "  ${B}https://t.me/proxy?server=${ip}&port=${pt}&secret=${fs}${NC}"
    echo ""
}
presskey() {
    echo ""
    echo -ne "  ${DIM}按 Enter 返回...${NC}"
    read -r
}
do_install() {
    banner
    if chk; then
        warn "已安装, 如需重装请先卸载"
        presskey
        return
    fi
    if ! check_dependencies; then presskey; return; fi
    echo -e "  ${B}* 全新安装 Telemt${NC}"
    line
    echo ""; info "正在获取公网 IP..."
    PIP=$(get_ip)
    if [ -z "$PIP" ]; then
        warn "无法获取公网 IP"
        echo -ne "  ${B}> 手动输入IP: ${NC}"
        read -r PIP
    else
        ok "公网 IP: $PIP"
    fi
    echo ""; echo -e "  ${B}* 基础配置${NC}"
    echo ""; RP=$(rnd_port)
    while true; do
        echo -ne "  ${B}> 端口 [$RP]: ${NC}"
        read -r input_port
        PT=${input_port:-$RP}
        valid_port "$PT" && break
        warn "端口必须是 1-65535 的数字"
    done
    while true; do
        echo -ne "  ${B}> 伪装域名 [www.tesla.com]: ${NC}"
        read -r input_domain
        DM=${input_domain:-www.tesla.com}
        valid_domain "$DM" && break
        warn "请输入有效域名"
    done
    echo ""; echo -e "  ${B}* 用户配置${NC}"
    echo ""; while true; do
        echo -ne "  ${B}> 用户名 [proxy]: ${NC}"
        read -r input_user
        UN=${input_user:-proxy}
        valid_user "$UN" && break
        warn "用户名只能包含字母、数字、下划线和连字符"
    done
    SC=$(openssl rand -hex 16)
    ok "已生成密钥: $SC"
    echo ""; line
    echo ""; echo -e "  ${B}* 确认配置${NC}"
    echo ""; echo -e "  ${B}  IP:       $PIP${NC}"
    echo -e "  ${B}  端口:     $PT${NC}"
    echo -e "  ${B}  域名:     $DM${NC}"
    echo -e "  ${B}  用户名:   $UN${NC}"
    echo -e "  ${B}  密钥:     $SC${NC}"
    echo ""; echo -ne "  ${B}> 确认安装? [Y/n]: ${NC}"
    read -r input_confirm
    if [ "$input_confirm" = "n" ] || [ "$input_confirm" = "N" ]; then
        warn "已取消"
        presskey
        return
    fi
    echo ""; line
    echo ""; echo -e "  ${B}[1/5] 下载并校验...${NC}"
    local td
    td=$(mktemp -d) || { err "无法创建临时目录"; presskey; return; }
    if download_release "$td" && install -m 0755 "$td/telemt" "$BP"; then
        rm -rf "$td"
        ok "程序已安装"
    else
        rm -rf "$td"
        err "下载失败"
        presskey
        return
    fi
    echo -e "  ${B}[2/5] 写入配置...${NC}"
    cat > "$CF" <<EOF
[general]
use_middle_proxy = false
[general.modes]
classic = false
secure = false
tls = true
[general.links]
show = "*"
public_host = "$PIP"
public_port = $PT
[censorship]
tls_domain = "$DM"
mask = true
[server]
port = $PT
[[server.listeners]]
ip = "0.0.0.0"
[access.users]
$UN = "$SC"
EOF
    ok "配置完成"
    echo -e "  ${B}[3/5] 创建服务...${NC}"
    cat > "$SF" <<EOF
[Unit]
Description=Telemt
After=network.target
[Service]
Type=simple
ExecStart=$BP $CF
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
    ok "服务已创建"
    echo -e "  ${B}[4/5] 启动服务...${NC}"
    systemctl daemon-reload
    systemctl enable telemt 2>/dev/null
    if systemctl start telemt && sleep 2 && systemctl is-active --quiet telemt; then
        ok "已启动并设置开机自启"
    else
        err "服务启动失败"
        journalctl -u telemt -n 10 --no-pager 2>/dev/null
        presskey
        return
    fi
    echo -e "  ${B}[5/5] 生成链接...${NC}"
    echo ""
    line
    echo ""
    echo -e "  ${B}===== Telemt 安装成功! =====${NC}"
    echo ""
    links "$PIP" "$PT" "$UN" "$SC" "$DM"
    presskey
}
do_update() {
    banner
    if ! chk; then err "未安装"; presskey; return; fi
    if ! check_dependencies; then presskey; return; fi
    echo -e "  ${B}* 更新 Telemt${NC}"
    line
    echo ""
    local current latest td was_active=false
    current=$(get_version)
    latest=$(get_latest_version)
    info "当前版本: ${current:-未知}"
    info "最新版本: ${latest:-获取失败}"
    if [ -n "$latest" ] && [ "$current" = "$latest" ]; then
        echo ""
        echo -ne "  ${B}> 已是最新版，是否重新安装? [y/N]: ${NC}"
        read -r yn
        if [ "$yn" != "y" ] && [ "$yn" != "Y" ]; then
            info "无需更新"
            presskey
            return
        fi
    fi
    echo ""
    echo -e "  ${B}[1/4] 下载并校验...${NC}"
    td=$(mktemp -d) || { err "无法创建临时目录"; presskey; return; }
    if ! download_release "$td"; then
        rm -rf "$td"
        err "下载失败"
        presskey
        return
    fi
    echo -e "  ${B}[2/4] 备份并替换程序...${NC}"
    systemctl is-active --quiet telemt 2>/dev/null && was_active=true
    cp -p "$BP" "${BP}.bak" || {
        rm -rf "$td"
        err "备份失败"
        presskey
        return
    }
    $was_active && systemctl stop telemt 2>/dev/null
    if ! install -m 0755 "$td/telemt" "$BP"; then
        cp -p "${BP}.bak" "$BP"
        $was_active && systemctl start telemt
        rm -rf "$td"
        err "替换失败，已恢复原版本"
        presskey
        return
    fi
    rm -rf "$td"
    echo -e "  ${B}[3/4] 检查新版本...${NC}"
    if ! $was_active; then
        rm -f "${BP}.bak"
        echo -e "  ${B}[4/4] 更新完成${NC}"
        ok "当前版本: $(get_version)"
        info "服务保持停止状态"
    elif systemctl start telemt && sleep 2 && systemctl is-active --quiet telemt; then
        rm -f "${BP}.bak"
        echo -e "  ${B}[4/4] 更新完成${NC}"
        ok "当前版本: $(get_version)"
    else
        err "新版本启动失败，正在回滚"
        systemctl stop telemt 2>/dev/null
        install -m 0755 "${BP}.bak" "$BP"
        rm -f "${BP}.bak"
        if $was_active; then
            systemctl start telemt
        fi
        warn "已恢复版本: $(get_version)"
        journalctl -u telemt -n 10 --no-pager 2>/dev/null
    fi
    presskey
}
do_links() {
    banner
    if ! chk; then err "未安装"; presskey; return; fi
    echo -e "  ${B}* 连接链接${NC}"
    line
    echo ""
    links
    presskey
}
do_svc() {
    if ! chk; then banner; err "未安装"; presskey; return; fi
    while true; do
        banner
        echo -e "  ${B}* 服务管理${NC}        状态: $(status)"
        line
        echo ""
        echo -e "  ${CYAN}${B}1)${NC} 启动服务"
        echo -e "  ${CYAN}${B}2)${NC} 停止服务"
        echo -e "  ${CYAN}${B}3)${NC} 重启服务"
        echo -e "  ${CYAN}${B}4)${NC} 开启开机自启"
        echo -e "  ${CYAN}${B}5)${NC} 关闭开机自启"
        echo -e "  ${DIM}0) 返回主菜单${NC}"
        echo ""
        echo -ne "  ${B}> 选择 [0-5]: ${NC}"
        read -r c
        echo ""
        case "$c" in
            1) if systemctl start telemt; then ok "服务已启动"; else err "启动失败"; fi ;;
            2) if systemctl stop telemt; then ok "服务已停止"; else err "停止失败"; fi ;;
            3) if systemctl restart telemt; then ok "服务已重启"; else err "重启失败"; fi ;;
            4) if systemctl enable telemt >/dev/null 2>&1; then ok "已开启开机自启"; else err "设置失败"; fi ;;
            5) if systemctl disable telemt >/dev/null 2>&1; then ok "已关闭开机自启"; else err "设置失败"; fi ;;
            0) return ;;
            *) warn "无效选择" ;;
        esac
        presskey
    done
}
do_st() {
    banner
    echo -e "  ${B}* 服务状态${NC}"
    line
    echo ""
    systemctl status telemt --no-pager -l 2>/dev/null || warn "服务未运行或尚未安装"
    presskey
}
do_log() {
    banner
    echo -e "  ${B}* 运行日志${NC}"
    line
    echo ""
    journalctl -u telemt -n 50 --no-pager 2>/dev/null || err "无日志"
    presskey
}
do_cfg() {
    if [ ! -f "$CF" ]; then banner; err "无配置文件"; presskey; return; fi
    while true; do
        banner
        echo -e "  ${B}* 配置管理${NC}        配置: ${GREEN}已加载${NC}"
        line
        echo ""
        echo -e "  ${CYAN}${B}1)${NC} 修改伪装域名"
        echo -e "  ${CYAN}${B}2)${NC} 修改端口"
        echo -e "  ${CYAN}${B}3)${NC} 添加用户"
        echo -e "  ${CYAN}${B}4)${NC} 使用编辑器打开"
        echo -e "  ${DIM}0) 返回主菜单${NC}"
        echo ""
        echo -ne "  ${B}> 选择 [0-4]: ${NC}"
        read -r c
        echo ""
        case "$c" in
        1)
            local od
            od=$(sed -n 's/^[[:space:]]*tls_domain[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$CF" | head -1)
            info "当前域名: $od"
            echo -ne "  ${B}> 新域名: ${NC}"
            read -r nd
            if [ -n "$nd" ] && valid_domain "$nd"; then
                sed -i.bak "0,/^[[:space:]]*tls_domain[[:space:]]*=/s|^[[:space:]]*tls_domain[[:space:]]*=.*|tls_domain = \"$nd\"|" "$CF"
                ok "已更新"
                echo -ne "  ${B}> 重启? [Y/n]: ${NC}"
                read -r yn
                if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
                    systemctl restart telemt && ok "已重启"
                fi
            elif [ -n "$nd" ]; then
                warn "域名格式无效"
            fi
            ;;
        2)
            local op
            op=$(get_port)
            info "当前端口: $op"
            echo -ne "  ${B}> 新端口: ${NC}"
            read -r np
            if [ -n "$np" ] && valid_port "$np"; then
                cp -p "$CF" "${CF}.bak"
                sed -i \
                    -e "s/^[[:space:]]*public_port[[:space:]]*=.*/public_port = $np/" \
                    -e "0,/^[[:space:]]*port[[:space:]]*=/s/^[[:space:]]*port[[:space:]]*=.*/port = $np/" "$CF"
                ok "已更新"
                echo -ne "  ${B}> 重启? [Y/n]: ${NC}"
                read -r yn
                if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
                    systemctl restart telemt && ok "已重启"
                fi
            elif [ -n "$np" ]; then
                warn "端口必须是 1-65535 的数字"
            fi
            ;;
        3)
            echo -ne "  ${B}> 新用户名: ${NC}"
            read -r nu
            if [ -n "$nu" ] && valid_user "$nu"; then
                local ns
                ns=$(openssl rand -hex 16)
                cp -p "$CF" "${CF}.bak"
                echo "$nu = \"$ns\"" >> "$CF"
                ok "用户: $nu"
                ok "密钥: $ns"
                echo -ne "  ${B}> 重启? [Y/n]: ${NC}"
                read -r yn
                if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
                    systemctl restart telemt && ok "已重启"
                fi
            elif [ -n "$nu" ]; then
                warn "用户名只能包含字母、数字、下划线和连字符"
            fi
            ;;
        4) nano "$CF" 2>/dev/null || vi "$CF" ;;
        0) return ;;
        *) warn "无效选择" ;;
        esac
        presskey
    done
}
do_rm() {
    banner
    echo -e "  ${B}* 卸载 Telemt${NC}"
    line
    echo ""
    echo -ne "  ${B}> 确定卸载? [y/N]: ${NC}"
    read -r yn
    if [ "$yn" != "y" ] && [ "$yn" != "Y" ]; then
        info "已取消"
        presskey
        return
    fi
    systemctl stop telemt 2>/dev/null
    systemctl disable telemt 2>/dev/null
    rm -f "$BP" "$SF"
    systemctl daemon-reload
    echo -ne "  ${B}> 删除配置? [y/N]: ${NC}"
    read -r dc
    if [ "$dc" = "y" ] || [ "$dc" = "Y" ]; then
        rm -f "$CF"
        ok "配置已删除"
    fi
    ok "已卸载"
    presskey
}
menu() {
    banner
    local port version auto_start
    port=$(get_port)
    version=$(get_version)
    if systemctl is-enabled --quiet telemt 2>/dev/null; then
        auto_start="${GREEN}已开启${NC}"
    else
        auto_start="${DIM}未开启${NC}"
    fi
    echo -e "  ${B}运行状态${NC}  $(status)"
    echo -e "  ${B}程序版本${NC}  ${version:--}"
    echo -e "  ${B}监听端口${NC}  ${port:--}"
    echo -e "  ${B}开机自启${NC}  $auto_start"
    line
    echo ""
    echo -e "  ${CYAN}${B}1)${NC} 安装 Telemt          ${CYAN}${B}5)${NC} 查看状态"
    echo -e "  ${CYAN}${B}2)${NC} 检查并更新           ${CYAN}${B}6)${NC} 运行日志"
    echo -e "  ${CYAN}${B}3)${NC} 查看连接链接         ${CYAN}${B}7)${NC} 配置管理"
    echo -e "  ${CYAN}${B}4)${NC} 服务管理             ${RED}${B}8)${NC} 卸载 Telemt"
    echo ""
    echo -e "  ${DIM}0) 退出${NC}"
    echo ""
    line
    echo ""
    echo -ne "  ${B}> 选择 [0-8]: ${NC}"
}
[ "$(id -u)" -ne 0 ] && echo -e "\n  ${B}[X] 请用 root 运行${NC}\n" && exit 1
while true; do
    menu
    read -r c
    case "$c" in
        1) do_install;; 2) do_update;; 3) do_links;; 4) do_svc;;
        5) do_st;; 6) do_log;; 7) do_cfg;; 8) do_rm;;
        0) echo ""; echo -e "  ${B}再见!${NC}"; echo ""; exit 0;;
        *) echo ""; warn "无效选择，请输入 0-8"; sleep 1;;
    esac
done

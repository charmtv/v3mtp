#!/usr/bin/env python3
import os

script = r"""#!/bin/bash
# Telemt v3 - https://github.com/charmtv/v3mtp
B='\033[1m'
DIM='\033[2m'
NC='\033[0m'
CF=/etc/telemt.toml
BP=/usr/local/bin/telemt
SF=/etc/systemd/system/telemt.service
GH=https://github.com/charmtv/v3mtp
banner() {
    clear
    echo ""
    echo -e "${B}=================================================${NC}"
    echo -e "${B}        Telemt v3 管理工具${NC}"
    echo -e "${B}     高性能 Telegram MTProto 代理${NC}"
    echo -e "${B}${NC}"
    echo -e "${B}  by: 米粒${NC}"
    echo -e "${B}  TG群: https://t.me/mlkjfx6${NC}"
    echo -e "${B}=================================================${NC}"
    echo ""
}
line() { echo -e "  ${DIM}-----------------------------------------------${NC}"; }
ok()   { echo -e "  ${B}[OK] $1${NC}"; }
warn() { echo -e "  ${B}[!] $1${NC}"; }
err()  { echo -e "  ${B}[X] $1${NC}"; }
info() { echo -e "  ${B}[i] $1${NC}"; }
ask() {
    local p="$1" d="$2" r
    if [ -n "$d" ]; then
        echo -ne "  ${B}> $p [$d]: ${NC}"
    else
        echo -ne "  ${B}> $p: ${NC}"
    fi
    read r
    if [ -z "$r" ]; then echo "$d"; else echo "$r"; fi
}
wait_key() {
    echo ""
    echo -ne "  ${DIM}按 Enter 返回...${NC}"
    read
}
get_ip() {
    local i
    i=$(curl -4 -s --max-time 5 https://api.ipify.org 2>/dev/null)
    [ -z "$i" ] && i=$(curl -4 -s --max-time 5 https://ifconfig.me 2>/dev/null)
    [ -z "$i" ] && i=$(curl -4 -s --max-time 5 https://icanhazip.com 2>/dev/null)
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
            echo -e "${B}[运行中]${NC}"
        else
            echo -e "${B}[已停止]${NC}"
        fi
    else
        echo -e "${DIM}[未安装]${NC}"
    fi
}
links() {
    local ip="$1" pt="$2" us="$3" sc="$4" dm="$5"
    if [ -z "$ip" ]; then
        ip=$(get_ip)
        [ -z "$ip" ] && ip=YOUR_IP
    fi
    if [ -z "$pt" ]; then
        pt=$(grep 'port = ' "$CF" 2>/dev/null | head -1 | tr -dc '0-9')
        [ -z "$pt" ] && pt=443
    fi
    if [ -z "$sc" ]; then
        local ln
        ln=$(grep -v '#' "$CF" 2>/dev/null | grep '= "' | grep -v tls | grep -v public | head -1)
        us=$(echo "$ln" | cut -d= -f1 | tr -d ' ')
        sc=$(echo "$ln" | cut -d'"' -f2)
    fi
    if [ -z "$dm" ]; then
        dm=$(grep tls_domain "$CF" 2>/dev/null | cut -d'"' -f2)
        [ -z "$dm" ] && dm=www.tesla.com
    fi
    local hd
    hd=$(printf '%s' "$dm" | xxd -p | tr -d '\n')
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
do_install() {
    banner
    if chk; then
        warn 'Already installed, uninstall first'
        wait_key
        return
    fi
    echo -e "  ${B}* 全新安装 Telemt${NC}"
    line
    echo ""
    info 'Getting public IP...'
    PIP=$(get_ip)
    if [ -z "$PIP" ]; then
        warn 'Cannot get public IP'
        PIP=$(ask 'Enter IP' '')
    else
        ok "IP: $PIP"
    fi
    echo ""
    echo -e "  ${B}* 基础配置${NC}"
    echo ""
    RP=$(rnd_port)
    PT=$(ask 'Port' "$RP")
    DM=$(ask 'Domain' 'www.tesla.com')
    echo ""
    echo -e "  ${B}* 用户配置${NC}"
    echo ""
    UN=$(ask 'Username' 'MLKJFX')
    SC=$(openssl rand -hex 16)
    ok "Secret: $SC"
    echo ""
    line
    echo ""
    echo -e "  ${B}* 确认配置${NC}"
    echo ""
    echo -e "  ${B}  IP:       $PIP${NC}"
    echo -e "  ${B}  Port:     $PT${NC}"
    echo -e "  ${B}  Domain:   $DM${NC}"
    echo -e "  ${B}  User:     $UN${NC}"
    echo -e "  ${B}  Secret:   $SC${NC}"
    echo ""
    CF2=$(ask 'Install? (Y/n)' 'Y')
    if [ "$CF2" = n ] || [ "$CF2" = N ]; then
        warn 'Cancelled'
        wait_key
        return
    fi
    echo ""
    line
    echo ""
    echo -e "  ${B}[1/5] Downloading...${NC}"
    local ar lc
    ar=$(uname -m)
    lc=gnu
    ldd --version 2>&1 | grep -iq musl && lc=musl
    if wget -qO- "$GH/releases/latest/download/telemt-${ar}-linux-${lc}.tar.gz" | tar xz 2>/dev/null; then
        mv telemt "$BP" && chmod +x "$BP"
        ok 'Downloaded'
    else
        err 'Download failed'
        wait_key
        return
    fi
    echo -e "  ${B}[2/5] Writing config...${NC}"
    cat > "$CF" <<EOF
[general]
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
    ok 'Config done'
    echo -e "  ${B}[3/5] Creating service...${NC}"
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
    ok 'Service created'
    echo -e "  ${B}[4/5] Starting...${NC}"
    systemctl daemon-reload
    systemctl start telemt
    systemctl enable telemt 2>/dev/null
    ok 'Started'
    echo -e "  ${B}[5/5] Generating links...${NC}"
    sleep 2
    echo ""
    line
    echo ""
    echo -e "  ${B}===== Telemt OK! =====${NC}"
    echo ""
    links "$PIP" "$PT" "$UN" "$SC" "$DM"
    wait_key
}
do_update() {
    banner
    if ! chk; then err 'Not installed'; wait_key; return; fi
    echo -e "  ${B}* Update${NC}"
    line
    echo ""
    echo -e "  ${B}[1/3] Stopping...${NC}"
    systemctl stop telemt 2>/dev/null
    ok 'Stopped'
    echo -e "  ${B}[2/3] Downloading...${NC}"
    local ar lc
    ar=$(uname -m)
    lc=gnu
    ldd --version 2>&1 | grep -iq musl && lc=musl
    if wget -qO- "$GH/releases/latest/download/telemt-${ar}-linux-${lc}.tar.gz" | tar xz 2>/dev/null; then
        mv telemt "$BP" && chmod +x "$BP"
        ok 'Downloaded'
    else
        err 'Failed'
        systemctl start telemt
        wait_key
        return
    fi
    echo -e "  ${B}[3/3] Starting...${NC}"
    systemctl start telemt
    ok 'Done!'
    wait_key
}
do_links() {
    banner
    if ! chk; then err 'Not installed'; wait_key; return; fi
    echo -e "  ${B}* Links${NC}"
    line
    echo ""
    links
    wait_key
}
do_svc() {
    banner
    if ! chk; then err 'Not installed'; wait_key; return; fi
    echo -e "  ${B}* Service${NC}"
    line
    echo ""
    echo -e "  ${B}1)${NC} Start"
    echo -e "  ${B}2)${NC} Stop"
    echo -e "  ${B}3)${NC} Restart"
    echo -e "  ${B}0)${NC} Back"
    echo ""
    echo -ne "  ${B}> Choice: ${NC}"
    read c
    echo ""
    case "$c" in
        1) systemctl start telemt && ok 'Started';;
        2) systemctl stop telemt && ok 'Stopped';;
        3) systemctl restart telemt && ok 'Restarted';;
        0) return;;
    esac
    wait_key
}
do_st() {
    banner
    echo -e "  ${B}* Status${NC}"
    line
    echo ""
    systemctl status telemt --no-pager -l 2>/dev/null || err 'Not installed'
    wait_key
}
do_log() {
    banner
    echo -e "  ${B}* Logs${NC}"
    line
    echo ""
    journalctl -u telemt -n 30 --no-pager 2>/dev/null || err 'No logs'
    wait_key
}
do_cfg() {
    banner
    if [ ! -f "$CF" ]; then err 'No config'; wait_key; return; fi
    echo -e "  ${B}* Config${NC}"
    line
    echo ""
    echo -e "  ${B}1)${NC} Change domain"
    echo -e "  ${B}2)${NC} Change port"
    echo -e "  ${B}3)${NC} Add user"
    echo -e "  ${B}4)${NC} Edit file"
    echo -e "  ${B}0)${NC} Back"
    echo ""
    echo -ne "  ${B}> Choice: ${NC}"
    read c
    echo ""
    case "$c" in
        1)
            local od nd yn
            od=$(grep tls_domain "$CF" | cut -d'"' -f2)
            info "Current: $od"
            nd=$(ask 'New domain' '')
            if [ -n "$nd" ]; then
                sed -i "s|$od|$nd|g" "$CF"
                ok 'Updated'
                yn=$(ask 'Restart? (Y/n)' 'Y')
                if [ "$yn" != n ] && [ "$yn" != N ]; then
                    systemctl restart telemt && ok 'Restarted'
                fi
            fi
            ;;
        2)
            local op np yn
            op=$(grep 'port = ' "$CF" | head -1 | tr -dc '0-9')
            info "Current: $op"
            np=$(ask 'New port' '')
            if [ -n "$np" ]; then
                sed -i "s|port = $op|port = $np|g" "$CF"
                ok 'Updated'
                yn=$(ask 'Restart? (Y/n)' 'Y')
                if [ "$yn" != n ] && [ "$yn" != N ]; then
                    systemctl restart telemt && ok 'Restarted'
                fi
            fi
            ;;
        3)
            local nu ns yn
            nu=$(ask 'New username' '')
            if [ -n "$nu" ]; then
                ns=$(openssl rand -hex 16)
                echo "$nu = \"$ns\"" >> "$CF"
                ok "User: $nu"
                ok "Secret: $ns"
                yn=$(ask 'Restart? (Y/n)' 'Y')
                if [ "$yn" != n ] && [ "$yn" != N ]; then
                    systemctl restart telemt && ok 'Restarted'
                fi
            fi
            ;;
        4) nano "$CF" 2>/dev/null || vi "$CF";;
        0) return;;
    esac
    wait_key
}
do_rm() {
    banner
    echo -e "  ${B}* Uninstall${NC}"
    line
    echo ""
    local yn dc
    yn=$(ask 'Uninstall? (y/N)' 'N')
    if [ "$yn" != y ] && [ "$yn" != Y ]; then
        info 'Cancelled'
        wait_key
        return
    fi
    systemctl stop telemt 2>/dev/null
    systemctl disable telemt 2>/dev/null
    rm -f "$BP" "$SF"
    systemctl daemon-reload
    dc=$(ask 'Delete config? (y/N)' 'N')
    if [ "$dc" = y ] || [ "$dc" = Y ]; then
        rm -f "$CF"
        ok 'Config deleted'
    fi
    ok 'Uninstalled'
    wait_key
}
menu() {
    banner
    echo -e "  ${B}Status:${NC} $(status)"
    line
    echo ""
    echo -e "  ${B}1)${NC}  安装 Telemt"
    echo -e "  ${B}2)${NC}  更新 Telemt"
    echo -e "  ${B}3)${NC}  查看连接链接"
    echo -e "  ${B}4)${NC}  服务管理"
    echo -e "  ${B}5)${NC}  查看状态"
    echo -e "  ${B}6)${NC}  查看日志"
    echo -e "  ${B}7)${NC}  修改配置"
    echo -e "  ${B}8)${NC}  卸载"
    echo ""
    echo -e "  ${B}0)${NC}  退出"
    echo ""
    line
    echo ""
    echo -ne "  ${B}> [0-8]: ${NC}"
}
[ "$(id -u)" -ne 0 ] && echo -e "\n  ${B}[X] Run as root${NC}\n" && exit 1
while true; do
    menu
    read c
    case "$c" in
        1) do_install;; 2) do_update;; 3) do_links;; 4) do_svc;;
        5) do_st;; 6) do_log;; 7) do_cfg;; 8) do_rm;;
        0) echo ""; echo -e "  ${B}Bye!${NC}"; echo ""; exit 0;;
    esac
done
"""

path = r'c:\Users\Administrator\Desktop\telemt-main\telemt-main\install.sh'
with open(path, 'wb') as f:
    f.write(script.encode('utf-8').replace(b'\r\n', b'\n'))
print('Written with LF line endings')

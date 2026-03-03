#!/bin/bash
# Telemt v3 - https://mtp.813099.xyz
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
    echo -e "${B}=================================================${NC}"
    echo ""
}
line() { echo -e "  ${DIM}-----------------------------------------------${NC}"; }
ok()   { echo -e "  ${B}[OK] $1${NC}"; }
warn() { echo -e "  ${B}[!] $1${NC}"; }
err()  { echo -e "  ${B}[X] $1${NC}"; }
info() { echo -e "  ${B}[i] $1${NC}"; }
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
presskey() {
    echo ""
    echo -ne "  ${DIM}按 Enter 返回...${NC}"
    read dummy
}
do_install() {
    banner
    if chk; then
        warn "已安装, 如需重装请先卸载"
        presskey
        return
    fi
    echo -e "  ${B}* 全新安装 Telemt${NC}"
    line
    echo ""
    info "正在获取公网 IP..."
    PIP=$(get_ip)
    if [ -z "$PIP" ]; then
        warn "无法获取公网 IP"
        echo -ne "  ${B}> 手动输入IP: ${NC}"
        read PIP
    else
        ok "公网 IP: $PIP"
    fi
    echo ""
    echo -e "  ${B}* 基础配置${NC}"
    echo ""
    RP=$(rnd_port)
    echo -ne "  ${B}> 端口 [$RP]: ${NC}"
    read input_port
    PT=${input_port:-$RP}
    echo -ne "  ${B}> 伪装域名 [www.tesla.com]: ${NC}"
    read input_domain
    DM=${input_domain:-www.tesla.com}
    echo ""
    echo -e "  ${B}* 用户配置${NC}"
    echo ""
    echo -ne "  ${B}> 用户名 [MLKJFX]: ${NC}"
    read input_user
    UN=${input_user:-MLKJFX}
    SC=$(openssl rand -hex 16)
    ok "已生成密钥: $SC"
    echo ""
    line
    echo ""
    echo -e "  ${B}* 确认配置${NC}"
    echo ""
    echo -e "  ${B}  IP:       $PIP${NC}"
    echo -e "  ${B}  端口:     $PT${NC}"
    echo -e "  ${B}  域名:     $DM${NC}"
    echo -e "  ${B}  用户名:   $UN${NC}"
    echo -e "  ${B}  密钥:     $SC${NC}"
    echo ""
    echo -ne "  ${B}> 确认安装? [Y/n]: ${NC}"
    read input_confirm
    if [ "$input_confirm" = "n" ] || [ "$input_confirm" = "N" ]; then
        warn "已取消"
        presskey
        return
    fi
    echo ""
    line
    echo ""
    echo -e "  ${B}[1/5] 下载中...${NC}"
    local ar lc
    ar=$(uname -m)
    lc=gnu
    ldd --version 2>&1 | grep -iq musl && lc=musl
    if wget -qO- "$GH/releases/latest/download/telemt-${ar}-linux-${lc}.tar.gz" | tar xz 2>/dev/null; then
        mv telemt "$BP" && chmod +x "$BP"
        ok "下载完成"
    else
        err "下载失败"
        presskey
        return
    fi
    echo -e "  ${B}[2/5] 写入配置...${NC}"
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
    systemctl start telemt
    systemctl enable telemt 2>/dev/null
    ok "已启动"
    echo -e "  ${B}[5/5] 生成链接...${NC}"
    sleep 2
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
    echo -e "  ${B}* 更新 Telemt${NC}"
    line
    echo ""
    echo -e "  ${B}[1/3] 停止服务...${NC}"
    systemctl stop telemt 2>/dev/null
    ok "已停止"
    echo -e "  ${B}[2/3] 下载中...${NC}"
    local ar lc
    ar=$(uname -m)
    lc=gnu
    ldd --version 2>&1 | grep -iq musl && lc=musl
    if wget -qO- "$GH/releases/latest/download/telemt-${ar}-linux-${lc}.tar.gz" | tar xz 2>/dev/null; then
        mv telemt "$BP" && chmod +x "$BP"
        ok "下载完成"
    else
        err "下载失败"
        systemctl start telemt
        presskey
        return
    fi
    echo -e "  ${B}[3/3] 启动服务...${NC}"
    systemctl start telemt
    ok "更新完成!"
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
    banner
    if ! chk; then err "未安装"; presskey; return; fi
    echo -e "  ${B}* 服务管理${NC}"
    line
    echo ""
    echo -e "  ${B}1)${NC} 启动"
    echo -e "  ${B}2)${NC} 停止"
    echo -e "  ${B}3)${NC} 重启"
    echo -e "  ${B}0)${NC} 返回"
    echo ""
    echo -ne "  ${B}> 选择: ${NC}"
    read c
    echo ""
    case "$c" in
        1) systemctl start telemt && ok "已启动";;
        2) systemctl stop telemt && ok "已停止";;
        3) systemctl restart telemt && ok "已重启";;
        0) return;;
    esac
    presskey
}
do_st() {
    banner
    echo -e "  ${B}* 服务状态${NC}"
    line
    echo ""
    systemctl status telemt --no-pager -l 2>/dev/null || err "未安装"
    presskey
}
do_log() {
    banner
    echo -e "  ${B}* 运行日志${NC}"
    line
    echo ""
    journalctl -u telemt -n 30 --no-pager 2>/dev/null || err "无日志"
    presskey
}
do_cfg() {
    banner
    if [ ! -f "$CF" ]; then err "无配置文件"; presskey; return; fi
    echo -e "  ${B}* 修改配置${NC}"
    line
    echo ""
    echo -e "  ${B}1)${NC} 修改伪装域名"
    echo -e "  ${B}2)${NC} 修改端口"
    echo -e "  ${B}3)${NC} 添加用户"
    echo -e "  ${B}4)${NC} 编辑器打开"
    echo -e "  ${B}0)${NC} 返回"
    echo ""
    echo -ne "  ${B}> 选择: ${NC}"
    read c
    echo ""
    case "$c" in
        1)
            local od
            od=$(grep tls_domain "$CF" | cut -d'"' -f2)
            info "当前域名: $od"
            echo -ne "  ${B}> 新域名: ${NC}"
            read nd
            if [ -n "$nd" ]; then
                sed -i "s|$od|$nd|g" "$CF"
                ok "已更新"
                echo -ne "  ${B}> 重启? [Y/n]: ${NC}"
                read yn
                if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
                    systemctl restart telemt && ok "已重启"
                fi
            fi
            ;;
        2)
            local op
            op=$(grep 'port = ' "$CF" | head -1 | tr -dc '0-9')
            info "当前端口: $op"
            echo -ne "  ${B}> 新端口: ${NC}"
            read np
            if [ -n "$np" ]; then
                sed -i "s|port = $op|port = $np|g" "$CF"
                ok "已更新"
                echo -ne "  ${B}> 重启? [Y/n]: ${NC}"
                read yn
                if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
                    systemctl restart telemt && ok "已重启"
                fi
            fi
            ;;
        3)
            echo -ne "  ${B}> 新用户名: ${NC}"
            read nu
            if [ -n "$nu" ]; then
                local ns
                ns=$(openssl rand -hex 16)
                echo "$nu = \"$ns\"" >> "$CF"
                ok "用户: $nu"
                ok "密钥: $ns"
                echo -ne "  ${B}> 重启? [Y/n]: ${NC}"
                read yn
                if [ "$yn" != "n" ] && [ "$yn" != "N" ]; then
                    systemctl restart telemt && ok "已重启"
                fi
            fi
            ;;
        4) nano "$CF" 2>/dev/null || vi "$CF";;
        0) return;;
    esac
    presskey
}
do_rm() {
    banner
    echo -e "  ${B}* 卸载 Telemt${NC}"
    line
    echo ""
    echo -ne "  ${B}> 确定卸载? [y/N]: ${NC}"
    read yn
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
    read dc
    if [ "$dc" = "y" ] || [ "$dc" = "Y" ]; then
        rm -f "$CF"
        ok "配置已删除"
    fi
    ok "已卸载"
    presskey
}
menu() {
    banner
    echo -e "  ${B}状态:${NC} $(status)"
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
    echo -ne "  ${B}> 选择 [0-8]: ${NC}"
}
[ "$(id -u)" -ne 0 ] && echo -e "\n  ${B}[X] 请用 root 运行${NC}\n" && exit 1
while true; do
    menu
    read c
    case "$c" in
        1) do_install;; 2) do_update;; 3) do_links;; 4) do_svc;;
        5) do_st;; 6) do_log;; 7) do_cfg;; 8) do_rm;;
        0) echo ""; echo -e "  ${B}再见!${NC}"; echo ""; exit 0;;
    esac
done

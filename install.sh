#!/bin/bash
# Telemt v3 管理工具 - https://github.com/charmtv/v3mtp

B='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CONF_FILE="/etc/telemt.toml"
BIN_PATH="/usr/local/bin/telemt"
SERVICE_FILE="/etc/systemd/system/telemt.service"
REPO="https://github.com/charmtv/v3mtp"

print_banner() {
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

print_line() { echo -e "  ${DIM}-----------------------------------------------${NC}"; }
print_ok()   { echo -e "  ${B}[OK] $1${NC}"; }
print_warn() { echo -e "  ${B}[!] $1${NC}"; }
print_err()  { echo -e "  ${B}[X] $1${NC}"; }
print_info() { echo -e "  ${B}[i] $1${NC}"; }

ask() {
    local prompt="$1"
    local default="$2"
    local result
    if [ -n "$default" ]; then
        echo -ne "  ${B}> ${prompt} [${default}]: ${NC}"
    else
        echo -ne "  ${B}> ${prompt}: ${NC}"
    fi
    read -r result
    if [ -z "$result" ]; then
        echo "$default"
    else
        echo "$result"
    fi
}

press_enter() {
    echo ""
    echo -ne "  ${DIM}按 Enter 返回主菜单...${NC}"
    read -r
}

get_public_ip() {
    local ip=""
    ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://api.ipify.org 2>/dev/null)
    if [ -z "$ip" ]; then
        ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://ifconfig.me 2>/dev/null)
    fi
    if [ -z "$ip" ]; then
        ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://icanhazip.com 2>/dev/null)
    fi
    if [ -z "$ip" ]; then
        ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://checkip.amazonaws.com 2>/dev/null)
    fi
    ip=$(echo "$ip" | tr -d '[:space:]')
    echo "$ip"
}

get_random_port() {
    if command -v shuf >/dev/null 2>&1; then
        shuf -i 1024-63335 -n 1
    else
        echo $(( (RANDOM % 62312) + 1024 ))
    fi
}

is_installed() {
    if [ -f "$BIN_PATH" ] && systemctl list-unit-files 2>/dev/null | grep -q telemt.service; then
        return 0
    fi
    return 1
}

get_status() {
    if is_installed; then
        if systemctl is-active --quiet telemt 2>/dev/null; then
            echo -e "${B}[运行中]${NC}"
        else
            echo -e "${B}[已停止]${NC}"
        fi
    else
        echo -e "${DIM}[未安装]${NC}"
    fi
}

show_links() {
    local ip="$1"
    local port="$2"
    local user="$3"
    local secret="$4"
    local domain="$5"

    if [ -z "$ip" ]; then
        ip=$(get_public_ip)
        if [ -z "$ip" ]; then
            ip="YOUR_IP"
        fi
    fi
    if [ -z "$port" ]; then
        port=$(grep -o 'port = [0-9]*' "$CONF_FILE" 2>/dev/null | head -1 | grep -o '[0-9]*')
        if [ -z "$port" ]; then
            port="443"
        fi
    fi
    if [ -z "$secret" ]; then
        local line
        line=$(grep -E '^[^#\[]*=.*"[0-9a-fA-F]{32}"' "$CONF_FILE" 2>/dev/null | head -1)
        user=$(echo "$line" | sed 's/ *=.*//' | tr -d ' ')
        secret=$(echo "$line" | grep -o '"[0-9a-fA-F]*"' | tr -d '"')
    fi
    if [ -z "$domain" ]; then
        domain=$(grep 'tls_domain' "$CONF_FILE" 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
        if [ -z "$domain" ]; then
            domain="www.tesla.com"
        fi
    fi

    local hex_domain
    hex_domain=$(printf '%s' "$domain" | xxd -p | tr -d '\n')
    local full_secret="ee${secret}${hex_domain}"

    echo -e "  ${B}--- 连接信息 ---${NC}"
    echo ""
    echo -e "  ${B}  服务器:    ${ip}${NC}"
    echo -e "  ${B}  端口:      ${port}${NC}"
    echo -e "  ${B}  用户名:    ${user}${NC}"
    echo -e "  ${B}  密钥:      ${secret}${NC}"
    echo -e "  ${B}  伪装域名:  ${domain}${NC}"
    echo ""
    echo -e "  ${B}--- Telegram 连接链接 ---${NC}"
    echo ""
    echo -e "  ${B}tg://proxy?server=${ip}&port=${port}&secret=${full_secret}${NC}"
    echo ""
    echo -e "  ${B}https://t.me/proxy?server=${ip}&port=${port}&secret=${full_secret}${NC}"
    echo ""
}

do_install() {
    print_banner
    if is_installed; then
        print_warn "已安装 Telemt, 如需重装请先卸载"
        press_enter
        return
    fi

    echo -e "  ${B}* 全新安装 Telemt${NC}"
    print_line
    echo ""

    print_info "正在获取服务器公网 IP..."
    PUBLIC_IP=$(get_public_ip)
    if [ -z "$PUBLIC_IP" ]; then
        print_warn "无法自动获取公网 IP"
        PUBLIC_IP=$(ask "请手动输入服务器公网 IP" "")
    else
        print_ok "公网 IP: ${PUBLIC_IP}"
    fi
    echo ""

    echo -e "  ${B}* 基础配置${NC}"
    echo ""
    RANDOM_PORT=$(get_random_port)
    PORT=$(ask "监听端口" "$RANDOM_PORT")
    DOMAIN=$(ask "伪装域名" "www.tesla.com")
    echo ""
    echo -e "  ${B}* 用户配置${NC}"
    echo ""
    USERNAME=$(ask "用户名" "MLKJFX")
    SECRET=$(openssl rand -hex 16)
    print_ok "已自动生成密钥: ${SECRET}"

    echo ""
    print_line
    echo ""
    echo -e "  ${B}* 确认配置${NC}"
    echo ""
    echo -e "  ${B}  服务器 IP:  ${PUBLIC_IP}${NC}"
    echo -e "  ${B}  端口:       ${PORT}${NC}"
    echo -e "  ${B}  伪装域名:   ${DOMAIN}${NC}"
    echo -e "  ${B}  用户名:     ${USERNAME}${NC}"
    echo -e "  ${B}  密钥:       ${SECRET}${NC}"
    echo ""
    CONFIRM=$(ask "确认安装? (Y/n)" "Y")
    if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
        print_warn "已取消"
        press_enter
        return
    fi

    echo ""
    print_line
    echo ""

    echo -e "  ${B}[1/5] 下载最新版本...${NC}"
    local arch
    arch=$(uname -m)
    local libc="gnu"
    if ldd --version 2>&1 | grep -iq musl; then
        libc="musl"
    fi
    if wget -qO- "${REPO}/releases/latest/download/telemt-${arch}-linux-${libc}.tar.gz" | tar -xz 2>/dev/null; then
        mv telemt "$BIN_PATH"
        chmod +x "$BIN_PATH"
        print_ok "安装到 ${BIN_PATH}"
    else
        print_err "下载失败, 请检查网络"
        press_enter
        return
    fi

    echo -e "  ${B}[2/5] 生成配置文件...${NC}"
    cat > "$CONF_FILE" << CONF
# Telemt 配置文件
[general]
[general.modes]
classic = false
secure = false
tls = true

[general.links]
show = "*"
public_host = "${PUBLIC_IP}"
public_port = ${PORT}

[censorship]
tls_domain = "${DOMAIN}"
mask = true

[server]
port = ${PORT}

[[server.listeners]]
ip = "0.0.0.0"

[access.users]
${USERNAME} = "${SECRET}"
CONF
    print_ok "配置已写入 ${CONF_FILE}"

    echo -e "  ${B}[3/5] 创建系统服务...${NC}"
    cat > "$SERVICE_FILE" << 'SVC'
[Unit]
Description=Telemt MTProto Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/telemt /etc/telemt.toml
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SVC
    print_ok "服务已创建"

    echo -e "  ${B}[4/5] 启动服务...${NC}"
    systemctl daemon-reload
    systemctl start telemt
    systemctl enable telemt 2>/dev/null
    print_ok "服务已启动并设为开机自启"

    echo -e "  ${B}[5/5] 生成连接链接...${NC}"
    sleep 2

    echo ""
    print_line
    echo ""
    echo -e "  ${B}========== Telemt 安装成功! ==========${NC}"
    echo ""

    show_links "$PUBLIC_IP" "$PORT" "$USERNAME" "$SECRET" "$DOMAIN"

    press_enter
}

do_update() {
    print_banner
    if ! is_installed; then
        print_err "Telemt 尚未安装"
        press_enter
        return
    fi

    echo -e "  ${B}* 更新 Telemt${NC}"
    print_line
    echo ""

    echo -e "  ${B}[1/3] 停止服务...${NC}"
    systemctl stop telemt 2>/dev/null
    print_ok "服务已停止"

    echo -e "  ${B}[2/3] 下载最新版本...${NC}"
    local arch
    arch=$(uname -m)
    local libc="gnu"
    if ldd --version 2>&1 | grep -iq musl; then
        libc="musl"
    fi
    if wget -qO- "${REPO}/releases/latest/download/telemt-${arch}-linux-${libc}.tar.gz" | tar -xz 2>/dev/null; then
        mv telemt "$BIN_PATH"
        chmod +x "$BIN_PATH"
        print_ok "已更新到最新版本"
    else
        print_err "下载失败"
        systemctl start telemt 2>/dev/null
        press_enter
        return
    fi

    echo -e "  ${B}[3/3] 重启服务...${NC}"
    systemctl start telemt
    print_ok "服务已启动"

    echo ""
    print_ok "更新完成!"
    press_enter
}

do_show_links() {
    print_banner
    if ! is_installed; then
        print_err "Telemt 尚未安装"
        press_enter
        return
    fi

    echo -e "  ${B}* 连接链接${NC}"
    print_line
    echo ""
    show_links
    press_enter
}

do_service_control() {
    print_banner
    if ! is_installed; then
        print_err "Telemt 尚未安装"
        press_enter
        return
    fi

    echo -e "  ${B}* 服务管理${NC}"
    print_line
    echo ""
    echo -e "  ${B}1)${NC} 启动服务"
    echo -e "  ${B}2)${NC} 停止服务"
    echo -e "  ${B}3)${NC} 重启服务"
    echo -e "  ${B}0)${NC} 返回"
    echo ""
    echo -ne "  ${B}> 请选择: ${NC}"
    read -r choice
    echo ""

    case "$choice" in
        1) systemctl start telemt && print_ok "服务已启动" ;;
        2) systemctl stop telemt && print_ok "服务已停止" ;;
        3) systemctl restart telemt && print_ok "服务已重启" ;;
        0) return ;;
        *) print_warn "无效选择" ;;
    esac
    press_enter
}

do_status() {
    print_banner
    echo -e "  ${B}* 服务状态${NC}"
    print_line
    echo ""
    systemctl status telemt --no-pager -l 2>/dev/null || print_err "Telemt 未安装"
    press_enter
}

do_logs() {
    print_banner
    echo -e "  ${B}* 最近日志 (最后30行)${NC}"
    print_line
    echo ""
    journalctl -u telemt -n 30 --no-pager 2>/dev/null || print_err "无日志"
    press_enter
}

do_edit_config() {
    print_banner
    if [ ! -f "$CONF_FILE" ]; then
        print_err "配置文件不存在"
        press_enter
        return
    fi

    echo -e "  ${B}* 修改配置${NC}"
    print_line
    echo ""
    echo -e "  ${B}1)${NC} 修改伪装域名"
    echo -e "  ${B}2)${NC} 修改端口"
    echo -e "  ${B}3)${NC} 添加用户"
    echo -e "  ${B}4)${NC} 用编辑器打开配置文件"
    echo -e "  ${B}0)${NC} 返回"
    echo ""
    echo -ne "  ${B}> 请选择: ${NC}"
    read -r choice
    echo ""

    case "$choice" in
        1)
            local old_domain
            old_domain=$(grep 'tls_domain' "$CONF_FILE" | grep -o '"[^"]*"' | tr -d '"')
            print_info "当前域名: ${old_domain}"
            local new_domain
            new_domain=$(ask "新伪装域名" "")
            if [ -n "$new_domain" ]; then
                sed -i "s|tls_domain = \"${old_domain}\"|tls_domain = \"${new_domain}\"|" "$CONF_FILE"
                print_ok "域名已更新为: ${new_domain}"
                RESTART=$(ask "立即重启? (Y/n)" "Y")
                if [ "$RESTART" != "n" ] && [ "$RESTART" != "N" ]; then
                    systemctl restart telemt && print_ok "已重启"
                fi
            fi
            ;;
        2)
            local old_port
            old_port=$(grep -o 'port = [0-9]*' "$CONF_FILE" | head -1 | grep -o '[0-9]*')
            print_info "当前端口: ${old_port}"
            local new_port
            new_port=$(ask "新端口" "")
            if [ -n "$new_port" ]; then
                sed -i "s|port = ${old_port}|port = ${new_port}|g" "$CONF_FILE"
                print_ok "端口已更新为: ${new_port}"
                RESTART=$(ask "立即重启? (Y/n)" "Y")
                if [ "$RESTART" != "n" ] && [ "$RESTART" != "N" ]; then
                    systemctl restart telemt && print_ok "已重启"
                fi
            fi
            ;;
        3)
            local new_user
            new_user=$(ask "新用户名" "")
            if [ -n "$new_user" ]; then
                local new_secret
                new_secret=$(openssl rand -hex 16)
                sed -i "/\[access.users\]/a ${new_user} = \"${new_secret}\"" "$CONF_FILE"
                print_ok "已添加用户: ${new_user}"
                print_ok "密钥: ${new_secret}"
                RESTART=$(ask "立即重启? (Y/n)" "Y")
                if [ "$RESTART" != "n" ] && [ "$RESTART" != "N" ]; then
                    systemctl restart telemt && print_ok "已重启"
                fi
            fi
            ;;
        4)
            nano "$CONF_FILE" 2>/dev/null || vi "$CONF_FILE"
            print_warn "如修改了配置, 请重启: systemctl restart telemt"
            ;;
        0) return ;;
    esac
    press_enter
}

do_uninstall() {
    print_banner
    echo -e "  ${B}* 卸载 Telemt${NC}"
    print_line
    echo ""
    CONFIRM=$(ask "确定要卸载吗? (y/N)" "N")
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_info "已取消"
        press_enter
        return
    fi

    echo ""
    systemctl stop telemt 2>/dev/null
    systemctl disable telemt 2>/dev/null
    rm -f "$BIN_PATH" "$SERVICE_FILE"
    systemctl daemon-reload 2>/dev/null

    DEL_CONF=$(ask "同时删除配置文件? (y/N)" "N")
    if [ "$DEL_CONF" = "y" ] || [ "$DEL_CONF" = "Y" ]; then
        rm -f "$CONF_FILE"
        print_ok "配置文件已删除"
    fi

    print_ok "Telemt 已卸载"
    press_enter
}

show_menu() {
    print_banner
    local status
    status=$(get_status)
    echo -e "  ${B}当前状态: ${NC}${status}"
    print_line
    echo ""
    echo -e "  ${B}1)${NC}  安装 Telemt"
    echo -e "  ${B}2)${NC}  更新 Telemt"
    echo -e "  ${B}3)${NC}  查看连接链接"
    echo -e "  ${B}4)${NC}  服务管理 (启动/停止/重启)"
    echo -e "  ${B}5)${NC}  查看服务状态"
    echo -e "  ${B}6)${NC}  查看运行日志"
    echo -e "  ${B}7)${NC}  修改配置"
    echo -e "  ${B}8)${NC}  卸载 Telemt"
    echo ""
    echo -e "  ${B}0)${NC}  退出"
    echo ""
    print_line
    echo ""
    echo -ne "  ${B}> 请选择 [0-8]: ${NC}"
}

if [ "$(id -u)" -ne 0 ]; then
    echo ""
    echo -e "  ${B}[X] 请以 root 身份运行此脚本${NC}"
    echo -e "  ${DIM}使用: sudo bash install.sh${NC}"
    echo ""
    exit 1
fi

while true; do
    show_menu
    read -r choice
    case "$choice" in
        1) do_install ;;
        2) do_update ;;
        3) do_show_links ;;
        4) do_service_control ;;
        5) do_status ;;
        6) do_logs ;;
        7) do_edit_config ;;
        8) do_uninstall ;;
        0) echo ""; echo -e "  ${B}再见!${NC}"; echo ""; exit 0 ;;
        *) ;;
    esac
done

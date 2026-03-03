#!/bin/bash
# ============================================================
#  Telemt v3 一键部署脚本
#  https://github.com/charmtv/v3mtp
# ============================================================

# ── 颜色定义 ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── 图标 ──
CHECK="${GREEN}✔${NC}"
CROSS="${RED}✘${NC}"
ARROW="${CYAN}➜${NC}"
STAR="${YELLOW}★${NC}"
INFO="${BLUE}ℹ${NC}"

# ── 辅助函数 ──
print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}${WHITE}         ⚡ Telemt v3 一键部署工具 ⚡             ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}${DIM}         高性能 Telegram MTProto 代理             ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    local step=$1
    local total=$2
    local msg=$3
    echo -e "  ${PURPLE}[${step}/${total}]${NC} ${ARROW} ${msg}"
}

print_ok() {
    echo -e "  ${CHECK} $1"
}

print_warn() {
    echo -e "  ${STAR} ${YELLOW}$1${NC}"
}

print_err() {
    echo -e "  ${CROSS} ${RED}$1${NC}"
}

print_info() {
    echo -e "  ${INFO} ${DIM}$1${NC}"
}

print_line() {
    echo -e "${DIM}  ──────────────────────────────────────────────────${NC}"
}

# ── 读取用户输入（带默认值）──
ask() {
    local prompt=$1
    local default=$2
    local result
    echo -ne "  ${ARROW} ${WHITE}${prompt}${NC}"
    if [ -n "$default" ]; then
        echo -ne " ${DIM}[${default}]${NC}"
    fi
    echo -ne "${WHITE}: ${NC}"
    read -r result
    echo "${result:-$default}"
}

# ── 主程序 ──
main() {
    clear
    print_banner

    # 检查 root
    if [ "$(id -u)" -ne 0 ]; then
        print_err "请以 root 身份运行此脚本"
        echo -e "  ${DIM}使用: sudo bash install.sh${NC}"
        exit 1
    fi

    # ── 检查是否已安装 ──
    if systemctl list-unit-files 2>/dev/null | grep -q telemt.service; then
        # ══════════════════════════════════════
        #  更新模式
        # ══════════════════════════════════════
        echo -e "  ${INFO} ${YELLOW}检测到已安装的 Telemt，进入更新模式${NC}"
        print_line
        echo ""

        print_step 1 3 "停止当前服务..."
        systemctl stop telemt 2>/dev/null || true
        print_ok "服务已停止"

        print_step 2 3 "下载最新版本..."
        if wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz 2>/dev/null; then
            mv telemt /usr/local/bin/telemt
            chmod +x /usr/local/bin/telemt
            print_ok "已更新到最新版本"
        else
            print_err "下载失败，请检查网络连接"
            exit 1
        fi

        print_step 3 3 "重新启动服务..."
        systemctl start telemt
        print_ok "服务已启动"

        echo ""
        print_line
        echo -e "  ${CHECK} ${GREEN}${BOLD}Telemt 更新完成！${NC}"
        print_line
        echo ""
        echo -e "  ${ARROW} 查看状态: ${WHITE}systemctl status telemt${NC}"
        echo -e "  ${ARROW} 获取链接: ${WHITE}journalctl -u telemt -n -g 'links' --no-pager -o cat | tac${NC}"
        echo ""
        exit 0
    fi

    # ══════════════════════════════════════
    #  全新安装
    # ══════════════════════════════════════
    echo -e "  ${INFO} ${WHITE}开始全新安装，请按提示操作${NC}"
    print_line
    echo ""

    # ── 交互式配置 ──
    echo -e "  ${STAR} ${BOLD}${WHITE}基础配置${NC}"
    echo ""

    PORT=$(ask "监听端口" "443")
    DOMAIN=$(ask "伪装域名 (TLS 前端)" "www.google.com")

    echo ""
    echo -e "  ${STAR} ${BOLD}${WHITE}用户配置${NC}"
    echo ""
    USERNAME=$(ask "用户名" "hello")

    echo -ne "  ${ARROW} ${WHITE}密钥方式${NC} ${DIM}[1=自动生成 2=手动输入]${NC}${WHITE}: ${NC}"
    read -r SECRET_MODE
    
    if [ "$SECRET_MODE" = "2" ]; then
        SECRET=$(ask "输入32位HEX密钥" "")
        if [ ${#SECRET} -ne 32 ]; then
            print_warn "密钥长度不正确，自动生成新密钥"
            SECRET=$(openssl rand -hex 16)
        fi
    else
        SECRET=$(openssl rand -hex 16)
    fi

    echo ""
    print_line
    echo ""
    echo -e "  ${STAR} ${BOLD}${WHITE}确认配置${NC}"
    echo ""
    echo -e "  │ 端口     ${WHITE}${PORT}${NC}"
    echo -e "  │ 伪装域名 ${WHITE}${DOMAIN}${NC}"
    echo -e "  │ 用户名   ${WHITE}${USERNAME}${NC}"
    echo -e "  │ 密钥     ${WHITE}${SECRET}${NC}"
    echo ""
    echo -ne "  ${ARROW} ${WHITE}确认安装？${NC} ${DIM}[Y/n]${NC}${WHITE}: ${NC}"
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        print_warn "已取消安装"
        exit 0
    fi

    echo ""
    print_line
    echo ""

    # ── 步骤 1: 下载安装 ──
    print_step 1 5 "下载最新版本 Telemt..."
    if wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz 2>/dev/null; then
        mv telemt /usr/local/bin/telemt
        chmod +x /usr/local/bin/telemt
        print_ok "安装到 /usr/local/bin/telemt"
    else
        print_err "下载失败，请检查网络连接"
        exit 1
    fi

    # ── 步骤 2: 生成配置 ──
    print_step 2 5 "生成配置文件..."
    cat > /etc/telemt.toml << CONF
# ═══════════════════════════════════════
#  Telemt 配置文件 - 由一键脚本自动生成
# ═══════════════════════════════════════

[general]
# ad_tag = "00000000000000000000000000000000"

[general.modes]
classic = false
secure = false
tls = true

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
    print_ok "配置已写入 /etc/telemt.toml"

    # ── 步骤 3: 创建服务 ──
    print_step 3 5 "创建 Systemd 服务..."
    cat > /etc/systemd/system/telemt.service << 'SVC'
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

    # ── 步骤 4: 启动服务 ──
    print_step 4 5 "启动服务..."
    systemctl daemon-reload
    systemctl start telemt
    systemctl enable telemt 2>/dev/null
    print_ok "服务已启动并设为开机自启"

    # ── 步骤 5: 获取链接 ──
    print_step 5 5 "等待服务就绪..."
    sleep 3

    echo ""
    print_line
    echo ""
    echo -e "${GREEN}${BOLD}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}  ║           ✅  Telemt 安装成功！                  ║${NC}"
    echo -e "${GREEN}${BOLD}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    # 显示连接信息
    echo -e "  ${STAR} ${BOLD}${WHITE}连接信息${NC}"
    echo ""
    echo -e "  │ 端口      ${WHITE}${PORT}${NC}"
    echo -e "  │ 用户名    ${WHITE}${USERNAME}${NC}"
    echo -e "  │ 密钥      ${WHITE}${SECRET}${NC}"
    echo -e "  │ 伪装域名  ${WHITE}${DOMAIN}${NC}"
    echo ""

    # 获取公网 IP
    PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 api.ipify.org 2>/dev/null || echo "YOUR_SERVER_IP")

    # 生成 tg 链接
    HEX_DOMAIN=$(echo -n "${DOMAIN}" | xxd -p | tr -d '\n')
    FULL_SECRET="ee${SECRET}${HEX_DOMAIN}"

    echo -e "  ${STAR} ${BOLD}${WHITE}Telegram 连接链接${NC}"
    echo ""
    echo -e "  ${CYAN}tg://proxy?server=${PUBLIC_IP}&port=${PORT}&secret=${FULL_SECRET}${NC}"
    echo ""
    echo -e "  ${CYAN}https://t.me/proxy?server=${PUBLIC_IP}&port=${PORT}&secret=${FULL_SECRET}${NC}"
    echo ""

    print_line
    echo ""
    echo -e "  ${STAR} ${BOLD}${WHITE}常用命令${NC}"
    echo ""
    echo -e "  │ 查看状态   ${DIM}systemctl status telemt${NC}"
    echo -e "  │ 重启服务   ${DIM}systemctl restart telemt${NC}"
    echo -e "  │ 查看日志   ${DIM}journalctl -u telemt -f${NC}"
    echo -e "  │ 编辑配置   ${DIM}nano /etc/telemt.toml${NC}"
    echo -e "  │ 获取链接   ${DIM}journalctl -u telemt -n -g 'links' --no-pager -o cat | tac${NC}"
    echo ""
}

main "$@"

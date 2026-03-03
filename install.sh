#!/bin/bash
# ============================================================
#  Telemt v3 绠＄悊宸ュ叿
#  https://github.com/charmtv/v3mtp
# ============================================================

# 鈹€鈹€ 鏍峰紡 鈹€鈹€
B='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CONF_FILE="/etc/telemt.toml"
BIN_PATH="/usr/local/bin/telemt"
SERVICE_FILE="/etc/systemd/system/telemt.service"
REPO="https://github.com/charmtv/v3mtp"

# 鈹€鈹€ 杈呭姪鍑芥暟 鈹€鈹€
print_banner() {
    clear
    echo ""
    echo -e "${B}鈺斺晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晽${NC}"
    echo -e "${B}鈺?         鈿?Telemt v3 绠＄悊宸ュ叿 鈿?                鈺?{NC}"
    echo -e "${B}鈺?      楂樻€ц兘 Telegram MTProto 浠ｇ悊                鈺?{NC}"
    echo -e "${B}鈺?                                                   鈺?{NC}"
    echo -e "${B}鈺? by: 绫崇矑                                         鈺?{NC}"
    echo -e "${B}鈺? TG缇? https://t.me/mlkjfx6                       鈺?{NC}"
    echo -e "${B}鈺氣晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暆${NC}"
    echo ""
}

print_line() {
    echo -e "  ${DIM}鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€${NC}"
}

print_ok()   { echo -e "  ${B}鉁?$1${NC}"; }
print_warn() { echo -e "  ${B}鈿?$1${NC}"; }
print_err()  { echo -e "  ${B}鉁?$1${NC}"; }
print_info() { echo -e "  ${B}鈩?$1${NC}"; }

ask() {
    local prompt=$1 default=$2 result
    echo -ne "  ${B}鉃?${prompt}${NC}"
    [ -n "$default" ] && echo -ne " ${DIM}[${default}]${NC}"
    echo -ne "${B}: ${NC}"
    read -r result
    echo "${result:-$default}"
}

press_enter() {
    echo ""
    echo -ne "  ${DIM}鎸?Enter 杩斿洖涓昏彍鍗?..${NC}"
    read -r
}

get_public_ip() {
    local ip=""
    ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://api.ipify.org 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://ifconfig.me 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://icanhazip.com 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://ipinfo.io/ip 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -4 -s --connect-timeout 5 --max-time 8 https://checkip.amazonaws.com 2>/dev/null)
    ip=$(echo "$ip" | tr -d '[:space:]')
    echo "$ip"
}

get_random_port() {
    local port
    port=$(shuf -i 1024-63335 -n 1 2>/dev/null || echo $(( (RANDOM % 62312) + 1024 )))
    echo "$port"
}

is_installed() {
    [ -f "$BIN_PATH" ] && systemctl list-unit-files 2>/dev/null | grep -q telemt.service
}

get_status() {
    if is_installed; then
        if systemctl is-active --quiet telemt 2>/dev/null; then
            echo -e "${B}鈼?杩愯涓?{NC}"
        else
            echo -e "${B}鈼?宸插仠姝?{NC}"
        fi
    else
        echo -e "${DIM}鏈畨瑁?{NC}"
    fi
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 1: 瀹夎
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_install() {
    print_banner
    if is_installed; then
        print_warn "妫€娴嬪埌宸插畨瑁?Telemt锛屽闇€閲嶈璇峰厛鍗歌浇"
        press_enter
        return
    fi

    echo -e "  ${B}鈽?鍏ㄦ柊瀹夎 Telemt${NC}"
    print_line
    echo ""

    print_info "姝ｅ湪鑾峰彇鏈嶅姟鍣ㄥ叕缃?IP..."
    PUBLIC_IP=$(get_public_ip)
    if [ -z "$PUBLIC_IP" ]; then
        print_warn "鏃犳硶鑷姩鑾峰彇鍏綉 IP"
        PUBLIC_IP=$(ask "璇锋墜鍔ㄨ緭鍏ユ湇鍔″櫒鍏綉 IP" "")
    else
        print_ok "妫€娴嬪埌鍏綉 IP: ${PUBLIC_IP}"
    fi
    echo ""

    echo -e "  ${B}鈽?鍩虹閰嶇疆${NC}"
    echo ""
    RANDOM_PORT=$(get_random_port)
    PORT=$(ask "鐩戝惉绔彛" "${RANDOM_PORT}")
    DOMAIN=$(ask "浼鍩熷悕" "www.tesla.com")
    echo ""
    echo -e "  ${B}鈽?鐢ㄦ埛閰嶇疆${NC}"
    echo ""
    USERNAME=$(ask "鐢ㄦ埛鍚? "MLKJFX")

    echo -ne "  ${B}鉃?瀵嗛挜鏂瑰紡${NC} ${DIM}[1=鑷姩鐢熸垚 2=鎵嬪姩杈撳叆]${NC}${B}: ${NC}"
    read -r SECRET_MODE
    if [ "$SECRET_MODE" = "2" ]; then
        SECRET=$(ask "杈撳叆32浣岺EX瀵嗛挜" "")
        [ ${#SECRET} -ne 32 ] && { print_warn "瀵嗛挜闀垮害涓嶆纭紝鑷姩鐢熸垚"; SECRET=$(openssl rand -hex 16); }
    else
        SECRET=$(openssl rand -hex 16)
    fi

    echo ""
    print_line
    echo ""
    echo -e "  ${B}鈽?纭閰嶇疆${NC}"
    echo ""
    echo -e "  ${B}鈹? 鏈嶅姟鍣?IP  ${PUBLIC_IP}${NC}"
    echo -e "  ${B}鈹? 绔彛       ${PORT}${NC}"
    echo -e "  ${B}鈹? 浼鍩熷悕   ${DOMAIN}${NC}"
    echo -e "  ${B}鈹? 鐢ㄦ埛鍚?    ${USERNAME}${NC}"
    echo -e "  ${B}鈹? 瀵嗛挜       ${SECRET}${NC}"
    echo ""
    echo -ne "  ${B}鉃?纭瀹夎锛?{NC} ${DIM}[Y/n]${NC}${B}: ${NC}"
    read -r CONFIRM
    [[ "$CONFIRM" =~ ^[Nn] ]] && { print_warn "宸插彇娑?; press_enter; return; }

    echo ""
    print_line
    echo ""

    echo -e "  ${B}[1/5] 鉃?涓嬭浇鏈€鏂扮増鏈?..${NC}"
    if wget -qO- "${REPO}/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz 2>/dev/null; then
        mv telemt "$BIN_PATH" && chmod +x "$BIN_PATH"
        print_ok "瀹夎鍒?${BIN_PATH}"
    else
        print_err "涓嬭浇澶辫触锛岃妫€鏌ョ綉缁?; press_enter; return
    fi

    echo -e "  ${B}[2/5] 鉃?鐢熸垚閰嶇疆鏂囦欢...${NC}"
    cat > "$CONF_FILE" << CONF
# Telemt 閰嶇疆鏂囦欢 - 鑷姩鐢熸垚
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
    print_ok "閰嶇疆宸插啓鍏?${CONF_FILE}"

    echo -e "  ${B}[3/5] 鉃?鍒涘缓绯荤粺鏈嶅姟...${NC}"
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
    print_ok "鏈嶅姟宸插垱寤?

    echo -e "  ${B}[4/5] 鉃?鍚姩鏈嶅姟...${NC}"
    systemctl daemon-reload
    systemctl start telemt
    systemctl enable telemt 2>/dev/null
    print_ok "鏈嶅姟宸插惎鍔ㄥ苟璁句负寮€鏈鸿嚜鍚?

    echo -e "  ${B}[5/5] 鉃?鐢熸垚杩炴帴閾炬帴...${NC}"
    sleep 2

    echo ""
    print_line
    echo ""
    echo -e "${B}  鈺斺晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晽${NC}"
    echo -e "${B}  鈺?          鉁? Telemt 瀹夎鎴愬姛锛?                 鈺?{NC}"
    echo -e "${B}  鈺氣晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暆${NC}"
    echo ""

    show_links "$PUBLIC_IP" "$PORT" "$USERNAME" "$SECRET" "$DOMAIN"

    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鏄剧ず閾炬帴
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
show_links() {
    local ip=$1 port=$2 user=$3 secret=$4 domain=$5

    if [ -z "$ip" ]; then
        ip=$(get_public_ip)
        [ -z "$ip" ] && ip="YOUR_IP"
    fi
    if [ -z "$port" ]; then
        port=$(grep -oP '^\s*port\s*=\s*\K[0-9]+' "$CONF_FILE" 2>/dev/null || echo "443")
    fi
    if [ -z "$secret" ]; then
        local line=$(grep -E '^[^#\[]*=\s*"[0-9a-fA-F]{32}"' "$CONF_FILE" 2>/dev/null | head -1)
        user=$(echo "$line" | sed 's/\s*=.*//' | tr -d ' ')
        secret=$(echo "$line" | grep -oP '"[0-9a-fA-F]{32}"' | tr -d '"')
    fi
    if [ -z "$domain" ]; then
        domain=$(grep -oP 'tls_domain\s*=\s*"\K[^"]+' "$CONF_FILE" 2>/dev/null || echo "www.tesla.com")
    fi

    local hex_domain=$(echo -n "${domain}" | xxd -p | tr -d '\n')
    local full_secret="ee${secret}${hex_domain}"

    echo -e "  ${B}鈽?杩炴帴淇℃伅${NC}"
    echo ""
    echo -e "  ${B}鈹? 鏈嶅姟鍣?    ${ip}${NC}"
    echo -e "  ${B}鈹? 绔彛       ${port}${NC}"
    echo -e "  ${B}鈹? 鐢ㄦ埛鍚?    ${user}${NC}"
    echo -e "  ${B}鈹? 瀵嗛挜       ${secret}${NC}"
    echo -e "  ${B}鈹? 浼鍩熷悕   ${domain}${NC}"
    echo ""
    echo -e "  ${B}鈽?Telegram 杩炴帴閾炬帴${NC}"
    echo ""
    echo -e "  ${B}tg://proxy?server=${ip}&port=${port}&secret=${full_secret}${NC}"
    echo ""
    echo -e "  ${B}https://t.me/proxy?server=${ip}&port=${port}&secret=${full_secret}${NC}"
    echo ""
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 2: 鏇存柊
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_update() {
    print_banner
    if ! is_installed; then
        print_err "Telemt 灏氭湭瀹夎"
        press_enter; return
    fi

    echo -e "  ${B}鈽?鏇存柊 Telemt${NC}"
    print_line
    echo ""

    echo -e "  ${B}[1/3] 鉃?鍋滄鏈嶅姟...${NC}"
    systemctl stop telemt 2>/dev/null || true
    print_ok "鏈嶅姟宸插仠姝?

    echo -e "  ${B}[2/3] 鉃?涓嬭浇鏈€鏂扮増鏈?..${NC}"
    if wget -qO- "${REPO}/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz 2>/dev/null; then
        mv telemt "$BIN_PATH" && chmod +x "$BIN_PATH"
        print_ok "宸叉洿鏂板埌鏈€鏂扮増鏈?
    else
        print_err "涓嬭浇澶辫触"
        systemctl start telemt 2>/dev/null
        press_enter; return
    fi

    echo -e "  ${B}[3/3] 鉃?閲嶅惎鏈嶅姟...${NC}"
    systemctl start telemt
    print_ok "鏈嶅姟宸插惎鍔?

    echo ""
    print_ok "鏇存柊瀹屾垚锛?
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 3: 鏌ョ湅杩炴帴閾炬帴
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_show_links() {
    print_banner
    if ! is_installed; then
        print_err "Telemt 灏氭湭瀹夎"
        press_enter; return
    fi

    echo -e "  ${B}鈽?杩炴帴閾炬帴${NC}"
    print_line
    echo ""
    show_links
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 4: 鏈嶅姟绠＄悊
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_service_control() {
    print_banner
    if ! is_installed; then
        print_err "Telemt 灏氭湭瀹夎"
        press_enter; return
    fi

    echo -e "  ${B}鈽?鏈嶅姟绠＄悊${NC}"
    print_line
    echo ""
    echo -e "  ${B}1)${NC} 鍚姩鏈嶅姟"
    echo -e "  ${B}2)${NC} 鍋滄鏈嶅姟"
    echo -e "  ${B}3)${NC} 閲嶅惎鏈嶅姟"
    echo -e "  ${B}0)${NC} 杩斿洖"
    echo ""
    echo -ne "  ${B}鉃?璇烽€夋嫨: ${NC}"
    read -r choice
    echo ""

    case $choice in
        1) systemctl start telemt && print_ok "鏈嶅姟宸插惎鍔? ;;
        2) systemctl stop telemt && print_ok "鏈嶅姟宸插仠姝? ;;
        3) systemctl restart telemt && print_ok "鏈嶅姟宸查噸鍚? ;;
        0) return ;;
        *) print_warn "鏃犳晥閫夋嫨" ;;
    esac
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 5: 鏌ョ湅鐘舵€?# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_status() {
    print_banner
    echo -e "  ${B}鈽?鏈嶅姟鐘舵€?{NC}"
    print_line
    echo ""
    systemctl status telemt --no-pager -l 2>/dev/null || print_err "Telemt 鏈畨瑁?
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 6: 鏌ョ湅鏃ュ織
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_logs() {
    print_banner
    echo -e "  ${B}鈽?鏈€杩戞棩蹇楋紙鏈€鍚?30 琛岋級${NC}"
    print_line
    echo ""
    journalctl -u telemt -n 30 --no-pager 2>/dev/null || print_err "鏃犳棩蹇?
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 7: 淇敼閰嶇疆
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_edit_config() {
    print_banner
    if [ ! -f "$CONF_FILE" ]; then
        print_err "閰嶇疆鏂囦欢涓嶅瓨鍦?
        press_enter; return
    fi

    echo -e "  ${B}鈽?淇敼閰嶇疆${NC}"
    print_line
    echo ""
    echo -e "  ${B}1)${NC} 淇敼浼鍩熷悕"
    echo -e "  ${B}2)${NC} 淇敼绔彛"
    echo -e "  ${B}3)${NC} 娣诲姞鐢ㄦ埛"
    echo -e "  ${B}4)${NC} 鐢ㄧ紪杈戝櫒鎵撳紑閰嶇疆鏂囦欢"
    echo -e "  ${B}0)${NC} 杩斿洖"
    echo ""
    echo -ne "  ${B}鉃?璇烽€夋嫨: ${NC}"
    read -r choice
    echo ""

    case $choice in
        1)
            local old_domain=$(grep -oP 'tls_domain\s*=\s*"\K[^"]+' "$CONF_FILE")
            print_info "褰撳墠鍩熷悕: ${old_domain}"
            local new_domain=$(ask "鏂颁吉瑁呭煙鍚? "")
            if [ -n "$new_domain" ]; then
                sed -i "s|tls_domain = \"${old_domain}\"|tls_domain = \"${new_domain}\"|" "$CONF_FILE"
                print_ok "鍩熷悕宸叉洿鏂颁负: ${new_domain}"
                print_warn "闇€瑕侀噸鍚湇鍔＄敓鏁?
                echo -ne "  ${B}鉃?绔嬪嵆閲嶅惎锛?{NC} ${DIM}[Y/n]${NC}: "
                read -r yn
                [[ ! "$yn" =~ ^[Nn] ]] && systemctl restart telemt && print_ok "宸查噸鍚?
            fi
            ;;
        2)
            local old_port=$(grep -oP '^\s*port\s*=\s*\K[0-9]+' "$CONF_FILE" | head -1)
            print_info "褰撳墠绔彛: ${old_port}"
            local new_port=$(ask "鏂扮鍙? "")
            if [ -n "$new_port" ]; then
                sed -i "s|port = ${old_port}|port = ${new_port}|g" "$CONF_FILE"
                print_ok "绔彛宸叉洿鏂颁负: ${new_port}"
                print_warn "闇€瑕侀噸鍚湇鍔＄敓鏁?
                echo -ne "  ${B}鉃?绔嬪嵆閲嶅惎锛?{NC} ${DIM}[Y/n]${NC}: "
                read -r yn
                [[ ! "$yn" =~ ^[Nn] ]] && systemctl restart telemt && print_ok "宸查噸鍚?
            fi
            ;;
        3)
            local new_user=$(ask "鏂扮敤鎴峰悕" "")
            if [ -n "$new_user" ]; then
                local new_secret=$(openssl rand -hex 16)
                sed -i "/\[access.users\]/a ${new_user} = \"${new_secret}\"" "$CONF_FILE"
                print_ok "宸叉坊鍔犵敤鎴? ${new_user}"
                print_ok "瀵嗛挜: ${new_secret}"
                print_warn "闇€瑕侀噸鍚湇鍔＄敓鏁?
                echo -ne "  ${B}鉃?绔嬪嵆閲嶅惎锛?{NC} ${DIM}[Y/n]${NC}: "
                read -r yn
                [[ ! "$yn" =~ ^[Nn] ]] && systemctl restart telemt && print_ok "宸查噸鍚?
            fi
            ;;
        4)
            nano "$CONF_FILE" 2>/dev/null || vi "$CONF_FILE"
            print_warn "濡備慨鏀逛簡閰嶇疆锛岃閲嶅惎鏈嶅姟: systemctl restart telemt"
            ;;
        0) return ;;
    esac
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  鍔熻兘 8: 鍗歌浇
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
do_uninstall() {
    print_banner
    echo -e "  ${B}鈽?鍗歌浇 Telemt${NC}"
    print_line
    echo ""
    echo -ne "  ${B}鉃?纭畾瑕佸嵏杞?Telemt 鍚楋紵${NC} ${DIM}[y/N]${NC}: "
    read -r confirm
    [[ ! "$confirm" =~ ^[Yy] ]] && { print_info "宸插彇娑?; press_enter; return; }

    echo ""
    systemctl stop telemt 2>/dev/null
    systemctl disable telemt 2>/dev/null
    rm -f "$BIN_PATH" "$SERVICE_FILE"
    systemctl daemon-reload 2>/dev/null

    echo -ne "  ${B}鉃?鏄惁鍚屾椂鍒犻櫎閰嶇疆鏂囦欢锛?{NC} ${DIM}[y/N]${NC}: "
    read -r del_conf
    [[ "$del_conf" =~ ^[Yy] ]] && rm -f "$CONF_FILE" && print_ok "閰嶇疆鏂囦欢宸插垹闄?

    print_ok "Telemt 宸插嵏杞?
    press_enter
}

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
#  涓昏彍鍗?# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
show_menu() {
    print_banner

    local status=$(get_status)
    echo -e "  ${B}鈩?褰撳墠鐘舵€?${NC} ${status}"
    print_line
    echo ""
    echo -e "  ${B}1)${NC}  瀹夎 Telemt"
    echo -e "  ${B}2)${NC}  鏇存柊 Telemt"
    echo -e "  ${B}3)${NC}  鏌ョ湅杩炴帴閾炬帴"
    echo -e "  ${B}4)${NC}  鏈嶅姟绠＄悊 (鍚姩/鍋滄/閲嶅惎)"
    echo -e "  ${B}5)${NC}  鏌ョ湅鏈嶅姟鐘舵€?
    echo -e "  ${B}6)${NC}  鏌ョ湅杩愯鏃ュ織"
    echo -e "  ${B}7)${NC}  淇敼閰嶇疆"
    echo -e "  ${B}8)${NC}  鍗歌浇 Telemt"
    echo ""
    echo -e "  ${B}0)${NC}  閫€鍑?
    echo ""
    print_line
    echo ""
    echo -ne "  ${B}鉃?璇烽€夋嫨 [0-8]: ${NC}"
}

# 鈹€鈹€ 妫€鏌?root 鈹€鈹€
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n  ${B}鉁?璇蜂互 root 韬唤杩愯姝よ剼鏈?{NC}"
    echo -e "  ${DIM}浣跨敤: sudo bash install.sh${NC}\n"
    exit 1
fi

# 鈹€鈹€ 涓诲惊鐜?鈹€鈹€
while true; do
    show_menu
    read -r choice
    case $choice in
        1) do_install ;;
        2) do_update ;;
        3) do_show_links ;;
        4) do_service_control ;;
        5) do_status ;;
        6) do_logs ;;
        7) do_edit_config ;;
        8) do_uninstall ;;
        0) echo ""; echo -e "  ${B}鉁?鍐嶈锛?{NC}"; echo ""; exit 0 ;;
        *) ;;
    esac
done

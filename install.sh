sudo bash -c '
set -e

# --- 检查是否已安装 ---
if systemctl list-unit-files | grep -q telemt.service; then
    # --- 更新模式 ---
    echo "--- 检测到已安装的 Telemt，开始更新... ---"

    echo "[*] 停止 telemt 服务..."
    systemctl stop telemt || true # 忽略错误（服务可能已停止）

    echo "[1/2] 下载最新版本 Telemt..."
    wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz

    echo "[1/2] 替换 /usr/local/bin 中的可执行文件..."
    mv telemt /usr/local/bin/telemt
    chmod +x /usr/local/bin/telemt

    echo "[2/2] 启动服务..."
    systemctl start telemt

    echo "--- Telemt 更新成功完成！ ---"
    echo
    echo "查看服务状态："
    echo "   systemctl status telemt"

else
    # --- 全新安装模式 ---
    echo "--- 开始自动安装 Telemt ---"

    # 步骤 1：下载并安装二进制文件
    echo "[1/5] 下载最新版本 Telemt..."
    wget -qO- "https://github.com/charmtv/v3mtp/releases/latest/download/telemt-$(uname -m)-linux-$(ldd --version 2>&1 | grep -iq musl && echo musl || echo gnu).tar.gz" | tar -xz

    echo "[1/5] 移动可执行文件到 /usr/local/bin 并设置权限..."
    mv telemt /usr/local/bin/telemt
    chmod +x /usr/local/bin/telemt

    # 步骤 2：生成密钥
    echo "[2/5] 生成密钥..."
    SECRET=$(openssl rand -hex 16)

    # 步骤 3：创建配置文件
    echo "[3/5] 创建配置文件 /etc/telemt.toml..."
    printf "# === 基本设置 ===\n[general]\n[general.modes]\nclassic = false\nsecure = false\ntls = true\n\n# === 反审查 & 伪装 ===\n[censorship]\n# !!! 重要：请替换为你要用于伪装的域名 !!!\ntls_domain = \"www.google.com\"\n\n[access.users]\nhello = \"%s\"\n" "$SECRET" > /etc/telemt.toml

    # 步骤 4：创建 Systemd 服务
    echo "[4/5] 创建 systemd 服务..."
    printf "[Unit]\nDescription=Telemt Proxy\nAfter=network.target\n\n[Service]\nType=simple\nExecStart=/usr/local/bin/telemt /etc/telemt.toml\nRestart=on-failure\nRestartSec=5\nLimitNOFILE=65536\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/telemt.service

    # 步骤 5：启动服务
    echo "[5/5] 重新加载 systemd，启动并设置开机自启..."
    systemctl daemon-reload
    systemctl start telemt
    systemctl enable telemt

    echo "--- Telemt 安装并启动成功！ ---"
    echo
    echo "重要信息："
    echo "==========="
    echo "1. 您需要编辑 /etc/telemt.toml 文件，将 '\''www.google.com'\'' 替换为其他域名"
    echo "   使用以下命令编辑："
    echo "   nano /etc/telemt.toml"
    echo "   编辑完成后重启服务："
    echo "   sudo systemctl restart telemt"
    echo
    echo "2. 查看服务状态："
    echo "   systemctl status telemt"
    echo
    echo "3. 获取连接链接："
    echo "   journalctl -u telemt -n -g '\''links'\'' --no-pager -o cat | tac"
fi
'

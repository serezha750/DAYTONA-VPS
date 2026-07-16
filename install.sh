#!/bin/bash

# 清屏，让仪表盘更清爽
clear

# ==========================================
# 🌟 高级颜色代码与特效
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 函数：逐字打印动画（打字效果）
type_effect() {
    local text="$1"
    local delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

# 函数：加载进度条动画
loading_bar() {
    local title="$1"
    echo -ne "${YELLOW}⏳ $title ${NC}[          ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[===       ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[======     ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[=========  ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[==========]"
    echo -e " ${GREEN}完成！${NC}"
}

# 自动检测 root / sudo 权限
if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

# ==========================================
# 主交互式列表菜单
# ==========================================
show_menu() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}          [👹 DXD LABS 高级 VPS 控制面板 👹]          ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}                ┌─────────────────────────┐               ${NC}"
    echo -e "${WHITE}                │   ${RED}█▀▀█ █──█ █▄─▄█ █▀▀█${WHITE}  │  <[宿傩 V2] ${NC}"
    echo -e "${WHITE}                │   ${RED}█▄▄█ █▄▄█ █ █ █ █▄▄█${WHITE}  │               ${NC}"
    echo -e "${WHITE}                └─────────────────────────┘               ${NC}"
    echo -e "${PURPLE}                   (█)─(█)     (█)─(█)                   ${NC}"
    echo -e "${PURPLE}                  █████████   █████████                  ${NC}"
    echo -e "${RED}                 ███████████████████████                 ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo -e "${CYAN}  ____  _____ _   _ ____     ____    _    __  __ ___ _   _  ____ ${NC}"
    echo -e "${CYAN} |  _ \| ____| | | |  _ \   / ___|  / \  |  \/  |_ _| \ | |/ ___|${NC}"
    echo -e "${CYAN} | | | |  _| | | | | |_) | | |  _  / _ \ | |\/| || ||  \| | |  _ ${NC}"
    echo -e "${CYAN} | |_| | |___| |_| |  __/  | |_| |/ ___ \| |  | || || |\  | |_| |${NC}"
    echo -e "${CYAN} |____/|_____|\___/|_|      \____/_/   \_\_|  |_|___|_| \_|\____|${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""
    echo -e "${YELLOW}👉 请从列表中选择一个选项：${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} 创建并启动新的 Ubuntu VPS 实例"
    echo -e "  ${CYAN}[2]${NC} 重启已有的 VPS 实例"
    echo -e "  ${CYAN}[3]${NC} 修改 TCP 端口转发规则（默认：2222）"
    echo -e "  ${CYAN}[4]${NC} 移除/清理 VPS 缓存文件"
    echo -e "  ${CYAN}[5]${NC} 退出控制面板"
    echo ""
    echo -e "${RED}==========================================================${NC}"
    echo -ne "${WHITE}🔹 请输入选项编号 [1-5]：${NC}"
    read CHOICE
    
    case $CHOICE in
        1) create_vps ;;
        2) restart_vps ;;
        3) configure_tcp ;;
        4) clean_vps ;;
        5) exit 0 ;;
        *) echo -e "${RED}❌ 无效选项！请输入 1-5。${NC}"; sleep 2; show_menu ;;
    esac
}

# 步骤 1：配置存储并下载云镜像
create_vps() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}⚙️  配置您的虚拟机规格${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""
    
    echo -ne "${BLUE}🔹 请输入内存大小（GB，例如 4、8、16、32）：${NC}"
    read RAM_GB
    echo -ne "${BLUE}🔹 请输入 CPU 核心数（例如 2、4、8）：${NC}"
    read CPU_CORES
    echo -ne "${BLUE}🔹 请输入要增加的磁盘空间（GB，例如 10、20）：${NC}"
    read DISK_ADD
    echo -ne "${BLUE}🔹 创建用户名（默认：ubuntu）：${NC}"
    read USER_NAME
    USER_NAME=${USER_NAME:-ubuntu}
    echo -ne "${BLUE}🔹 创建密码（默认：1234）：${NC}"
    read USER_PASS
    USER_PASS=${USER_PASS:-1234}
    
    # 2222 作为基础端口
    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=22

    echo ""
    echo -e "${YELLOW}⏳ 正在后台安装核心依赖，请稍候...${NC}"
    echo ""
    
    $SUDO_CMD apt-get update -y > /dev/null 2>&1
    $SUDO_CMD apt-get install -y qemu-system-x86 qemu-utils wget cloud-image-utils curl > /dev/null 2>&1
    
    # 构建自定义绝对路径架构
    $SUDO_CMD mkdir -p /home/daytona > /dev/null 2>&1
    
    if [ ! -f "/home/daytona/ubuntu22.qcow2" ]; then
        echo -e "${YELLOW}📥 正在下载 Ubuntu 22.04 云镜像到 /home/daytona/...${NC}"
        $SUDO_CMD wget -q --show-progress https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O /home/daytona/ubuntu22.qcow2
        $SUDO_CMD chmod 666 /home/daytona/ubuntu22.qcow2
    else
        echo -e "${GREEN}✅ 已检测到现有 Ubuntu 镜像缓存位于 /home/daytona/。${NC}"
    fi
    
    loading_bar "正在生成 Cloud-Init 配置"
    cat <<EOF > user-data
#cloud-config
ssh_pwauth: True
chpasswd:
  list: |
    ${USER_NAME}:${USER_PASS}
  expire: False
EOF

    cloud-localds seed.img user-data > /dev/null 2>&1
    loading_bar "正在扩展服务器硬盘容量"
    $SUDO_CMD qemu-img resize /home/daytona/ubuntu22.qcow2 +${DISK_ADD}G > /dev/null 2>&1
    
    save_env
    boot_qemu
}

# 步骤 2：网络端口转发修改
configure_tcp() {
    clear
    echo -e "${YELLOW}==========================================================${NC}"
    echo -e "${WHITE}🔄⚙️  管理自定义 TCP 端口转发规则${NC}"
    echo -e "${YELLOW}==========================================================${NC}"
    echo ""
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi
    echo -e "当前宿主机端口    ：${CYAN}${TCP_HOST_PORT:-2222}${NC}"
    echo -e "当前虚拟机端口    ：${CYAN}${TCP_GUEST_PORT:-22}${NC}"
    echo ""
    echo -ne "${BLUE}🔹 请输入新的外部宿主机端口（默认基础：2222）：${NC}"
    read NEW_HOST_PORT
    TCP_HOST_PORT=${NEW_HOST_PORT:-2222}
    
    echo -ne "${BLUE}🔹 请输入新的内部虚拟机端口（默认 SSH：22）：${NC}"
    read NEW_GUEST_PORT
    TCP_GUEST_PORT=${NEW_GUEST_PORT:-22}
    
    save_env
    echo ""
    echo -e "${GREEN}✅ TCP 规则已成功更新！${NC}"
    sleep 2
    show_menu
}

save_env() {
    echo "RAM_GB=${RAM_GB:-32}" > .vps_env
    echo "CPU_CORES=${CPU_CORES:-4}" >> .vps_env
    echo "USER_NAME=${USER_NAME:-ubuntu}" >> .vps_env
    echo "USER_PASS=${USER_PASS:-1234}" >> .vps_env
    echo "TCP_HOST_PORT=${TCP_HOST_PORT:-2222}" >> .vps_env
    echo "TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}" >> .vps_env
}

# ==========================================
# 🚀 启动虚拟机（含 sshx 永久日志）
# ==========================================
boot_qemu() {
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}
    RAM_VALUE="${RAM_GB:-32}G"

    clear
    echo -e "${GREEN}==========================================================${NC}"
    type_effect "👹 数据系统已同步！正在管道终端通道..." 0.02
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    # ========== ★ sshx.io 隧道启动与链接提取（永久日志） ★ ==========
    SSHX_LOG_FILE="/var/log/sshx.log"
    $SUDO_CMD mkdir -p "$(dirname "$SSHX_LOG_FILE")" 2>/dev/null
    # 尝试创建日志文件；若 /var/log 不可写则回退到 /tmp
    if ! $SUDO_CMD touch "$SSHX_LOG_FILE" 2>/dev/null; then
        SSHX_LOG_FILE="/tmp/sshx.log"
        touch "$SSHX_LOG_FILE" 2>/dev/null || { echo -e "${RED}无法创建日志文件${NC}"; exit 1; }
    fi
    # 后台启动隧道，输出重定向到固定日志文件
    curl -sSf https://sshx.io/get | sh -s run > "$SSHX_LOG_FILE" 2>&1 &
    
    # 等待 5 秒，让隧道完成初始化并输出 URL
    sleep 5
    # 从日志中提取公网链接
    SSHX_URL=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9]*' "$SSHX_LOG_FILE" | head -n 1)
    # ==================================================

    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "🎉       DEUP GAMING & DXD LABS - 虚拟机网络已激活        "
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${WHITE}👤 用户名 ：${CYAN}${USER_NAME:-ubuntu}${NC}"
    echo -e "${WHITE}🔑 密码    ：${CYAN}${USER_PASS:-1234}${NC}"
    echo -e "${WHITE}⚙️  资源    ：${CYAN}${RAM_VALUE} 内存 | ${CPU_CORES:-4} 核心${NC}"
    echo -e "${WHITE}🚀 端口规则 ：${YELLOW}宿主机端口 ${TCP_HOST_PORT} -> 虚拟机端口 ${TCP_GUEST_PORT}${NC}"
    echo -e "${RED}----------------------------------------------------------${NC}"
    # ★ 打印 sshx.io 公网链接（如果获取成功）★
    if [ ! -z "$SSHX_URL" ]; then
        echo -e "${YELLOW}🔥 公网 Web 访问链接（复制到浏览器中打开）：${NC}"
        echo -e "${GREEN}👉 $SSHX_URL 👈${NC}"
    else
        echo -e "${RED}⚠️ 隧道代理加载较慢，本地网络端口已在监听。${NC}"
    fi
    echo -e "${RED}----------------------------------------------------------${NC}"
    echo -e "${WHITE}👉 本地连接命令 ：ssh ${USER_NAME:-ubuntu}@localhost -p ${TCP_HOST_PORT}${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    echo ""
    
    # 🚀 执行 QEMU 启动虚拟机
    qemu-system-x86_64 \
        -hda /home/daytona/ubuntu22.qcow2 \
        -m $RAM_VALUE \
        -smp ${CPU_CORES:-4} \
        -drive file=seed.img,format=raw \
        -nographic \
        -netdev user,id=net0,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device e1000,netdev=net0
}

# 重启流程
restart_vps() {
    if [ -f "/home/daytona/ubuntu22.qcow2" ] && [ -f "seed.img" ]; then
        echo -e "${GREEN}🔄 正在重启现有服务器架构...${NC}"
        sleep 1
        boot_qemu
    else
        echo -e "${RED}❌ 未找到有效的配置文件块！请使用选项 1 进行构建。${NC}"
        sleep 3
        show_menu
    fi
}

# 清理流程
clean_vps() {
    echo -e "${RED}⚠️ 正在清除系统存储组件和配置...${NC}"
    $SUDO_CMD rm -rf user-data seed.img /home/daytona/ubuntu22.qcow2 .vps_env
    pkill sshx > /dev/null 2>&1
    pkill sh > /dev/null 2>&1
    sleep 1
    echo -e "${GREEN}✅ 工作区已成功擦除干净！${NC}"
    sleep 2
    show_menu
}

# 执行入口
show_menu

#!/bin/bash

# 清屏
# clear

# ==========================================
# 颜色代码（保留，不影响字符集）
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 逐字打印动画（打字效果）
type_effect() {
    local text="$1"
    local delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

# 进度条（纯 ASCII）
loading_bar() {
    local title="$1"
    echo -ne "${YELLOW}[*] $title ${NC}[          ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[===       ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[======     ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[=========  ]"
    sleep 0.3
    echo -ne "\b\b\b\b\b\b\b\b\b\b\b[==========]"
    echo -e " ${GREEN}Done!${NC}"
}

# 自动检测 root / sudo 权限
if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

# ==========================================
# 主菜单（纯 ASCII）
# ==========================================
show_menu() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}          [ DXD LABS VPS Control Panel ]               ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}  +--------------------------------------------+        ${NC}"
    echo -e "${WHITE}  |    DXD LABS  -  Ubuntu 22.04 VM Manager   |        ${NC}"
    echo -e "${WHITE}  +--------------------------------------------+        ${NC}"
    echo -e "${PURPLE}    (v)---(v)     (v)---(v)                            ${NC}"
    echo -e "${PURPLE}   ===========   ===========                           ${NC}"
    echo -e "${RED}  =============================================         ${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo -e "${CYAN}  ____  _____ _   _ ____     ____    _    __  __ ___ _   _  ____ ${NC}"
    echo -e "${CYAN} |  _ \| ____| | | |  _ \   / ___|  / \  |  \/  |_ _| \ | |/ ___|${NC}"
    echo -e "${CYAN} | | | |  _| | | | | |_) | | |  _  / _ \ | |\/| || ||  \| | |  _ ${NC}"
    echo -e "${CYAN} | |_| | |___| |_| |  __/  | |_| |/ ___ \| |  | || || |\  | |_| |${NC}"
    echo -e "${CYAN} |____/|_____|\___/|_|      \____/_/   \_\_|  |_|___|_| \_|\____|${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""
    echo -e "${YELLOW}Please select an option:${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create and start a new Ubuntu VPS instance"
    echo -e "  ${CYAN}[2]${NC} Restart an existing VPS instance"
    echo -e "  ${CYAN}[3]${NC} Modify TCP port forwarding (default: 2222)"
    echo -e "  ${CYAN}[4]${NC} Remove / clean VPS cache files"
    echo -e "  ${CYAN}[5]${NC} Exit control panel"
    echo ""
    echo -e "${RED}==========================================================${NC}"
    echo -ne "${WHITE}Enter option [1-5]: ${NC}"
    read CHOICE

    case $CHOICE in
        1) create_vps ;;
        2) restart_vps ;;
        3) configure_tcp ;;
        4) clean_vps ;;
        5) exit 0 ;;
        *) echo -e "${RED}[X] Invalid option! Please enter 1-5.${NC}"; sleep 2; show_menu ;;
    esac
}

# 创建虚拟机
create_vps() {
    clear
    echo -e "${RED}==========================================================${NC}"
    echo -e "${WHITE}Configure your VM specifications${NC}"
    echo -e "${RED}==========================================================${NC}"
    echo ""

    echo -ne "${BLUE}Enter RAM size (GB, e.g., 4,8,16,32): ${NC}"
    read RAM_GB
    echo -ne "${BLUE}Enter CPU cores (e.g., 2,4,8): ${NC}"
    read CPU_CORES
    echo -ne "${BLUE}Enter additional disk space (GB, e.g., 10,20): ${NC}"
    read DISK_ADD
    echo -ne "${BLUE}Enter username (default: ubuntu): ${NC}"
    read USER_NAME
    USER_NAME=${USER_NAME:-ubuntu}
    echo -ne "${BLUE}Enter password (default: 1234): ${NC}"
    read USER_PASS
    USER_PASS=${USER_PASS:-1234}

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=22

    echo ""
    echo -e "${YELLOW}Installing dependencies, please wait...${NC}"
    echo ""

    $SUDO_CMD apt-get update -y > /dev/null 2>&1
    $SUDO_CMD apt-get install -y qemu-system-x86 qemu-utils wget cloud-image-utils curl > /dev/null 2>&1

    $SUDO_CMD mkdir -p /home/daytona > /dev/null 2>&1

    if [ ! -f "/home/daytona/ubuntu22.qcow2" ]; then
        echo -e "${YELLOW}Downloading Ubuntu 22.04 cloud image to /home/daytona/...${NC}"
        $SUDO_CMD wget -q --show-progress https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O /home/daytona/ubuntu22.qcow2
        $SUDO_CMD chmod 666 /home/daytona/ubuntu22.qcow2
    else
        echo -e "${GREEN}[OK] Existing Ubuntu image found in /home/daytona/.${NC}"
    fi

    loading_bar "Generating Cloud-Init config"
    cat <<EOF > user-data
#cloud-config
ssh_pwauth: True
chpasswd:
  list: |
    ${USER_NAME}:${USER_PASS}
  expire: False
EOF

    cloud-localds seed.img user-data > /dev/null 2>&1
    loading_bar "Resizing disk image"
    $SUDO_CMD qemu-img resize /home/daytona/ubuntu22.qcow2 +${DISK_ADD}G > /dev/null 2>&1

    save_env
    boot_qemu
}

# 修改端口转发
configure_tcp() {
    clear
    echo -e "${YELLOW}==========================================================${NC}"
    echo -e "${WHITE}Manage custom TCP port forwarding${NC}"
    echo -e "${YELLOW}==========================================================${NC}"
    echo ""
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi
    echo -e "Current host port    : ${CYAN}${TCP_HOST_PORT:-2222}${NC}"
    echo -e "Current guest port   : ${CYAN}${TCP_GUEST_PORT:-22}${NC}"
    echo ""
    echo -ne "${BLUE}Enter new external host port (default: 2222): ${NC}"
    read NEW_HOST_PORT
    TCP_HOST_PORT=${NEW_HOST_PORT:-2222}

    echo -ne "${BLUE}Enter new internal VM port (default SSH 22): ${NC}"
    read NEW_GUEST_PORT
    TCP_GUEST_PORT=${NEW_GUEST_PORT:-22}

    save_env
    echo ""
    echo -e "${GREEN}[OK] TCP rules updated successfully!${NC}"
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

# 启动 QEMU
boot_qemu() {
    if [ -f ".vps_env" ]; then
        source .vps_env
    fi

    TCP_HOST_PORT=${TCP_HOST_PORT:-2222}
    TCP_GUEST_PORT=${TCP_GUEST_PORT:-22}
    RAM_VALUE="${RAM_GB:-32}G"

    clear
    echo -e "${GREEN}==========================================================${NC}"
    type_effect "[+] System data synchronized! Piping terminal channel..." 0.02
    echo -e "${GREEN}==========================================================${NC}"
    echo ""

    # sshx.io tunnel
    sshx_log=$(mktemp)
    curl -sSf https://sshx.io/get | sh -s run > "$sshx_log" 2>&1 &
    sleep 5
    SSHX_URL=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9]*' "$sshx_log" | head -n 1)

    clear
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "           DXD LABS - VM network activated"
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${WHITE}Username   : ${CYAN}${USER_NAME:-ubuntu}${NC}"
    echo -e "${WHITE}Password   : ${CYAN}${USER_PASS:-1234}${NC}"
    echo -e "${WHITE}Resources  : ${CYAN}${RAM_VALUE} RAM | ${CPU_CORES:-4} cores${NC}"
    echo -e "${WHITE}Port rule  : ${YELLOW}host ${TCP_HOST_PORT} -> guest ${TCP_GUEST_PORT}${NC}"
    echo -e "${RED}----------------------------------------------------------${NC}"
    if [ ! -z "$SSHX_URL" ]; then
        echo -e "${YELLOW}[!] Public web access URL (open in browser):${NC}"
        echo -e "${GREEN}  >> $SSHX_URL <<${NC}"
    else
        echo -e "${RED}[!] Tunnel loading slow, local port is listening.${NC}"
    fi
    echo -e "${RED}----------------------------------------------------------${NC}"
    echo -e "${WHITE}Local SSH command: ssh ${USER_NAME:-ubuntu}@localhost -p ${TCP_HOST_PORT}${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    echo ""

    qemu-system-x86_64 \
        -hda /home/daytona/ubuntu22.qcow2 \
        -m $RAM_VALUE \
        -smp ${CPU_CORES:-4} \
        -drive file=seed.img,format=raw \
        -nographic \
        -netdev user,id=net0,hostfwd=tcp::${TCP_HOST_PORT}-:${TCP_GUEST_PORT} \
        -device e1000,netdev=net0
}

# 重启
restart_vps() {
    if [ -f "/home/daytona/ubuntu22.qcow2" ] && [ -f "seed.img" ]; then
        echo -e "${GREEN}[+] Restarting existing VM...${NC}"
        sleep 1
        boot_qemu
    else
        echo -e "${RED}[X] Valid VM files not found. Please use option 1 to create.${NC}"
        sleep 3
        show_menu
    fi
}

# 清理
clean_vps() {
    echo -e "${RED}[!] Cleaning up VM files and configuration...${NC}"
    $SUDO_CMD rm -rf user-data seed.img /home/daytona/ubuntu22.qcow2 .vps_env
    pkill sshx > /dev/null 2>&1
    pkill sh > /dev/null 2>&1
    sleep 1
    echo -e "${GREEN}[OK] Workspace wiped clean!${NC}"
    sleep 2
    show_menu
}

# 入口
show_menu

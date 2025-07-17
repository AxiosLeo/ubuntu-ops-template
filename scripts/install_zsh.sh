#!/bin/bash

# install_zsh.sh - 安装 zsh 的脚本
# 支持多种 Linux 发行版和 macOS

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查是否已安装 zsh
check_zsh_installed() {
    if command_exists zsh; then
        print_message $GREEN "✓ zsh 已经安装，版本: $(zsh --version)"
        return 0
    else
        return 1
    fi
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            DISTRO=$ID
        elif [ -f /etc/redhat-release ]; then
            OS="Red Hat"
            DISTRO="rhel"
        elif [ -f /etc/debian_version ]; then
            OS="Debian"
            DISTRO="debian"
        else
            OS="Unknown Linux"
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        DISTRO="macos"
    else
        OS="Unknown"
        DISTRO="unknown"
    fi
}

# 安装 zsh
install_zsh() {
    print_message $BLUE "正在安装 zsh..."
    
    case $DISTRO in
        ubuntu|debian)
            print_message $YELLOW "检测到 Ubuntu/Debian 系统，使用 apt 安装..."
            sudo apt update
            sudo apt install -y zsh
            ;;
        centos|rhel|fedora)
            if command_exists dnf; then
                print_message $YELLOW "检测到 Fedora/RHEL 系统，使用 dnf 安装..."
                sudo dnf install -y zsh
            elif command_exists yum; then
                print_message $YELLOW "检测到 CentOS/RHEL 系统，使用 yum 安装..."
                sudo yum install -y zsh
            else
                print_message $RED "❌ 未找到 dnf 或 yum 包管理器"
                exit 1
            fi
            ;;
        arch)
            print_message $YELLOW "检测到 Arch Linux 系统，使用 pacman 安装..."
            sudo pacman -S --noconfirm zsh
            ;;
        opensuse*|sles)
            print_message $YELLOW "检测到 openSUSE 系统，使用 zypper 安装..."
            sudo zypper install -y zsh
            ;;
        alpine)
            print_message $YELLOW "检测到 Alpine Linux 系统，使用 apk 安装..."
            sudo apk add zsh
            ;;
        macos)
            if command_exists brew; then
                print_message $YELLOW "检测到 macOS 系统，使用 Homebrew 安装..."
                brew install zsh
            else
                print_message $YELLOW "检测到 macOS 系统，zsh 通常已预装"
                print_message $YELLOW "如果需要最新版本，请先安装 Homebrew: https://brew.sh"
            fi
            ;;
        *)
            print_message $RED "❌ 不支持的操作系统: $OS"
            print_message $YELLOW "请手动安装 zsh 或联系管理员"
            exit 1
            ;;
    esac
}

# 设置 zsh 为默认 shell
set_default_shell() {
    local zsh_path=$(which zsh)
    
    if [ -z "$zsh_path" ]; then
        print_message $RED "❌ 无法找到 zsh 可执行文件"
        return 1
    fi
    
    print_message $BLUE "zsh 安装路径: $zsh_path"
    
    # 检查 zsh 是否在 /etc/shells 中
    if ! grep -q "$zsh_path" /etc/shells; then
        print_message $YELLOW "将 zsh 添加到 /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    # 询问是否设置为默认 shell
    read -p "是否将 zsh 设置为默认 shell? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $BLUE "正在设置 zsh 为默认 shell..."
        chsh -s "$zsh_path"
        print_message $GREEN "✓ zsh 已设置为默认 shell"
        print_message $YELLOW "注意: 需要重新登录或重启终端才能生效"
    else
        print_message $YELLOW "跳过设置默认 shell"
    fi
}

# 安装 Oh My Zsh (可选)
install_oh_my_zsh() {
    read -p "是否安装 Oh My Zsh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message $BLUE "正在安装 Oh My Zsh..."
        if command_exists curl; then
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        elif command_exists wget; then
            sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
        else
            print_message $RED "❌ 需要 curl 或 wget 来下载 Oh My Zsh"
            return 1
        fi
        print_message $GREEN "✓ Oh My Zsh 安装完成"
    else
        print_message $YELLOW "跳过 Oh My Zsh 安装"
    fi
}

# 主函数
main() {
    print_message $BLUE "=== zsh 安装脚本 ==="
    
    # 检查是否已安装
    if check_zsh_installed; then
        read -p "zsh 已安装，是否继续设置? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message $YELLOW "安装已取消"
            exit 0
        fi
    else
        # 检测操作系统
        detect_os
        print_message $BLUE "检测到操作系统: $OS ($DISTRO)"
        
        # 安装 zsh
        install_zsh
        
        # 验证安装
        if check_zsh_installed; then
            print_message $GREEN "✓ zsh 安装成功"
        else
            print_message $RED "❌ zsh 安装失败"
            exit 1
        fi
    fi
    
    # 设置默认 shell
    set_default_shell
    
    # 可选安装 Oh My Zsh
    install_oh_my_zsh
    
    print_message $GREEN "=== 安装完成 ==="
    print_message $YELLOW "提示:"
    print_message $YELLOW "1. 如果设置了 zsh 为默认 shell，请重新登录或重启终端"
    print_message $YELLOW "2. 可以运行 'zsh' 立即切换到 zsh"
    print_message $YELLOW "3. 配置文件位于 ~/.zshrc"
}

# 运行主函数
main "$@"

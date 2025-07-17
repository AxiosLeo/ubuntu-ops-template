#!/bin/bash

# init_workspace.sh - 独立的工作空间初始化脚本
# 可以直接下载并运行，无需预先克隆仓库

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目仓库 URL
REPO_URL="https://github.com/AxiosLeo/ubuntu-ops-template.git"
WORKSPACE_DIR="/workspace"

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

# 检查系统依赖和要求
check_deps() {
    print_message $CYAN "检查系统依赖..."
    
    # 检查是否为 Ubuntu 系统
    if [ ! -f /etc/lsb-release ] || ! grep -q "Ubuntu" /etc/lsb-release 2>/dev/null; then
        print_message $YELLOW "警告: 此脚本专为 Ubuntu 设计"
    fi
    
    # 检查 sudo 权限
    if ! sudo -n true 2>/dev/null; then
        print_message $RED "错误: 需要 sudo 权限"
        exit 1
    fi
    
    # 检查网络连接
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        print_message $YELLOW "警告: 检测不到网络连接"
    fi
    
    # 检查必要命令
    if ! command_exists git; then
        print_message $YELLOW "Git 未安装，将在后续步骤中安装"
    fi
    
    print_message $GREEN "✓ 系统检查完成"
}

# 安装基本的 Git（如果还没安装）
install_basic_git() {
    if ! command_exists git; then
        print_message $BLUE "安装基本的 Git..."
        sudo apt update
        sudo apt install -y git
        print_message $GREEN "✓ Git 基本安装完成"
    else
        print_message $GREEN "✓ Git 已存在"
    fi
}

# 克隆仓库到工作空间
clone_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        print_message $CYAN "克隆仓库到 $WORKSPACE_DIR..."
        sudo git clone "$REPO_URL" "$WORKSPACE_DIR"
        sudo chown -R $USER:$USER "$WORKSPACE_DIR"
        print_message $GREEN "✓ 仓库已克隆到 $WORKSPACE_DIR"
    else
        print_message $YELLOW "⚠ $WORKSPACE_DIR 目录已存在"
        print_message $BLUE "检查现有工作空间..."
        
        # 检查是否为 git 仓库
        if [ -d "$WORKSPACE_DIR/.git" ]; then
            read -p "是否更新现有仓库？ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_message $CYAN "更新现有仓库..."
                cd "$WORKSPACE_DIR"
                git pull origin main || print_message $YELLOW "无法更新仓库，继续使用现有版本"
                print_message $GREEN "✓ 仓库更新完成"
            else
                print_message $YELLOW "跳过仓库更新"
            fi
        else
            print_message $YELLOW "目录存在但不是 git 仓库，跳过克隆操作"
        fi
        
        # 确保目录权限正确
        sudo chown -R $USER:$USER "$WORKSPACE_DIR" 2>/dev/null || true
    fi
    
    # 设置脚本权限（如果脚本目录存在）
    if [ -d "$WORKSPACE_DIR/scripts" ]; then
        chmod +x "$WORKSPACE_DIR"/scripts/*.sh 2>/dev/null || print_message $YELLOW "无法设置脚本权限，请手动检查"
        print_message $GREEN "✓ 脚本权限设置完成"
    else
        print_message $YELLOW "脚本目录不存在，跳过权限设置"
    fi
}

# 更新系统包
update_system() {
    print_message $CYAN "更新系统包..."
    sudo apt update && sudo apt upgrade -y
    sudo apt autoremove -y && sudo apt autoclean
    print_message $GREEN "✓ 系统更新完成"
}

# 安装 make 工具
install_make() {
    if ! command_exists make; then
        print_message $CYAN "安装 make 工具..."
        sudo apt install -y make build-essential
        print_message $GREEN "✓ make 安装完成: $(make --version | head -1)"
    else
        print_message $GREEN "✓ make 已存在: $(make --version | head -1)"
    fi
}

# 安装和配置 Git（使用仓库中的脚本）
install_git() {
    print_message $CYAN "安装和配置 Git..."
    if [ -f "$WORKSPACE_DIR/scripts/install_git.sh" ]; then
        cd "$WORKSPACE_DIR"
        chmod +x scripts/install_git.sh
        ./scripts/install_git.sh | exit 0
        print_message $GREEN "✓ Git 安装和配置完成"
    else
        print_message $RED "❌ 找不到 Git 安装脚本"
        exit 1
    fi
}

# 显示完成信息
show_completion_info() {
    print_message $GREEN "=== 工作空间初始化完成！ ==="
    echo
    print_message $BLUE "已完成的操作:"
    print_message $GREEN "✅ 设置适当的文件权限"
    print_message $GREEN "✅ 更新系统包"
    print_message $GREEN "✅ 安装 make 工具"
    print_message $GREEN "✅ 安装和配置 Git"
    print_message $GREEN "✅ 准备开发环境"
    echo
    print_message $BLUE "下一步操作:"
    print_message $YELLOW "  cd /workspace"
    print_message $YELLOW "  make help                # 查看所有可用命令"
    print_message $YELLOW "  make install-docker      # 安装 Docker"
    print_message $YELLOW "  make install-nodejs      # 安装 Node.js"
    print_message $YELLOW "  make install-python      # 安装 Python"
    print_message $YELLOW "  make install-all         # 安装所有软件"
    echo
    print_message $BLUE "环境配置选项:"
    print_message $YELLOW "  make setup-dev           # 完整开发环境"
    print_message $YELLOW "  make setup-web           # Web 服务器环境"
    print_message $YELLOW "  make setup-basic         # 基本服务器环境"
}

# 主函数
main() {
    print_message $CYAN "=== Ubuntu Ops Template 工作空间初始化 ==="
    echo
    
    # 检查系统依赖
    check_deps
    echo
    
    # 安装基本 Git
    install_basic_git
    echo
    
    # 克隆工作空间
    clone_workspace
    echo
    
    # 更新系统
    update_system
    echo
    
    # 安装 make 工具
    install_make
    echo
    
    # 安装和配置 Git
    install_git
    echo
    
    # 显示完成信息
    show_completion_info
}

# 运行主函数
main "$@"

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

# 检测是否为 CI 环境
is_ci_environment() {
    [[ "${CI}" == "true" ]] || [[ "${GITHUB_ACTIONS}" == "true" ]] || [[ "${GITLAB_CI}" == "true" ]] || [[ -n "${JENKINS_URL}" ]]
}

# 检测当前是否在仓库目录中
is_in_repo() {
    [ -f "Makefile" ] && [ -d "scripts" ] && [ -f "scripts/init_workspace.sh" ]
}

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
    
    # 在 CI 环境中跳过 sudo 权限检查
    if ! is_ci_environment; then
        # 检查 sudo 权限
        if ! sudo -n true 2>/dev/null; then
            print_message $RED "错误: 需要 sudo 权限"
            exit 1
        fi
    else
        print_message $BLUE "检测到 CI 环境，跳过 sudo 权限检查"
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
        if is_ci_environment; then
            # CI 环境中通常有 sudo 权限但不需要密码
            apt update && apt install -y git
        else
            sudo apt update
            sudo apt install -y git
        fi
        print_message $GREEN "✓ Git 基本安装完成"
    else
        print_message $GREEN "✓ Git 已存在"
    fi
}

# 克隆仓库到工作空间
clone_workspace() {
    # 如果当前已经在仓库中（常见于CI环境）
    if is_in_repo; then
        print_message $BLUE "检测到当前已在仓库目录中"
        if is_ci_environment; then
            print_message $BLUE "CI 环境：使用当前目录作为工作空间"
            WORKSPACE_DIR="$(pwd)"
        else
            # 非 CI 环境，询问是否使用当前目录
            read -p "是否使用当前目录作为工作空间？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                WORKSPACE_DIR="$(pwd)"
                print_message $GREEN "✓ 使用当前目录作为工作空间: $WORKSPACE_DIR"
            else
                print_message $BLUE "继续使用 /workspace 作为目标目录"
            fi
        fi
    fi
    
    # 如果不在仓库中，则需要克隆
    if ! is_in_repo; then
        if [ ! -d "$WORKSPACE_DIR" ]; then
            print_message $CYAN "克隆仓库到 $WORKSPACE_DIR..."
            if is_ci_environment; then
                git clone "$REPO_URL" "$WORKSPACE_DIR"
            else
                sudo git clone "$REPO_URL" "$WORKSPACE_DIR"
                sudo chown -R $USER:$USER "$WORKSPACE_DIR"
            fi
            print_message $GREEN "✓ 仓库已克隆到 $WORKSPACE_DIR"
        else
            print_message $YELLOW "⚠ $WORKSPACE_DIR 目录已存在"
            if is_ci_environment; then
                # CI 环境中自动更新仓库
                print_message $BLUE "CI 环境：自动更新现有仓库"
                cd "$WORKSPACE_DIR"
                git pull origin main || print_message $YELLOW "无法更新仓库，继续使用现有版本"
            else
                # 交互式环境中询问用户
                read -p "是否继续？这将更新现有仓库 (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cd "$WORKSPACE_DIR"
                    git pull origin main || print_message $YELLOW "无法更新仓库，继续使用现有版本"
                else
                    print_message $YELLOW "跳过仓库克隆"
                fi
            fi
        fi
    fi
    
    # 设置脚本权限
    chmod +x "$WORKSPACE_DIR"/scripts/*.sh
}

# 更新系统包
update_system() {
    print_message $CYAN "更新系统包..."
    if is_ci_environment; then
        # CI 环境中只更新包列表，跳过耗时的升级操作
        print_message $BLUE "CI 环境：仅更新包列表"
        apt update
    else
        sudo apt update && sudo apt upgrade -y
        sudo apt autoremove -y && sudo apt autoclean
    fi
    print_message $GREEN "✓ 系统更新完成"
}

# 安装和配置 Git（使用仓库中的脚本）
install_git() {
    print_message $CYAN "安装和配置 Git..."
    if is_ci_environment; then
        # CI 环境中跳过复杂的 Git 配置，Git 通常已预配置
        print_message $BLUE "CI 环境：跳过 Git 配置（通常已预配置）"
        print_message $GREEN "✓ Git 配置完成"
    else
        if [ -f "$WORKSPACE_DIR/scripts/install_git.sh" ]; then
            local current_dir=$(pwd)
            cd "$WORKSPACE_DIR"
            chmod +x scripts/install_git.sh
            ./scripts/install_git.sh
            cd "$current_dir"
            print_message $GREEN "✓ Git 安装和配置完成"
        else
            print_message $RED "❌ 找不到 Git 安装脚本: $WORKSPACE_DIR/scripts/install_git.sh"
            exit 1
        fi
    fi
}

# 显示完成信息
show_completion_info() {
    print_message $GREEN "=== 工作空间初始化完成！ ==="
    echo
    print_message $BLUE "已完成的操作:"
    print_message $GREEN "✅ 设置适当的文件权限"
    print_message $GREEN "✅ 更新系统包"
    print_message $GREEN "✅ 安装和配置 Git"
    print_message $GREEN "✅ 准备开发环境"
    echo
    print_message $BLUE "下一步操作:"
    if [ "$WORKSPACE_DIR" != "$(pwd)" ]; then
        print_message $YELLOW "  cd $WORKSPACE_DIR"
    fi
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
    
    # 安装和配置 Git
    install_git
    echo
    
    # 显示完成信息
    show_completion_info
}

# 运行主函数
main "$@"

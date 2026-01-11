#!/usr/bin/env bash
#
# Fingerprint sensor setup for ThinkPad T470 (Validity 138a:0097)
# Installs and configures python-validity, fprintd, and PAM integration
#

set -euo pipefail

SENSOR_ID="138a:0097"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root. It will ask for sudo when needed."
        exit 1
    fi
}

check_sensor() {
    log "Checking for fingerprint sensor..."

    local found=false
    for dev in /sys/bus/usb/devices/*/; do
        if [[ -f "${dev}idVendor" && -f "${dev}idProduct" ]]; then
            local vendor product
            vendor=$(cat "${dev}idVendor" 2>/dev/null)
            product=$(cat "${dev}idProduct" 2>/dev/null)
            if [[ "${vendor}:${product}" == "$SENSOR_ID" ]]; then
                found=true
                break
            fi
        fi
    done

    if [[ "$found" != "true" ]]; then
        log_error "Fingerprint sensor $SENSOR_ID not found"
        log_error "This script is designed for ThinkPad T470 with Validity sensor"
        exit 1
    fi

    log_success "Found Validity fingerprint sensor ($SENSOR_ID)"
}

check_aur_helper() {
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        log_error "No AUR helper found. Please install paru or yay first."
        exit 1
    fi
    log_success "Using AUR helper: $AUR_HELPER"
}

install_packages() {
    log "Installing required packages..."

    # Remove conflicting fprintd if installed (open-fprintd provides fprintd-clients-git)
    if pacman -Qi fprintd &>/dev/null; then
        log_warn "Removing conflicting 'fprintd' package (will be replaced by fprintd-clients-git)..."
        sudo pacman -Rdd --noconfirm fprintd
    fi

    # Official repo packages
    local official_pkgs=(
        imagemagick  # needed for python-validity
    )

    # AUR packages (open-fprintd pulls in fprintd-clients-git)
    local aur_pkgs=(
        python-validity
        open-fprintd
    )

    log "Installing official packages: ${official_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${official_pkgs[@]}"

    log "Installing AUR packages: ${aur_pkgs[*]}"
    log "Note: open-fprintd will install fprintd-clients-git as dependency"
    $AUR_HELPER -S --needed "${aur_pkgs[@]}"

    log_success "All packages installed"
}

initialize_sensor() {
    log "Initializing fingerprint sensor..."

    # Stop any existing services first
    sudo systemctl stop python3-validity.service 2>/dev/null || true

    # The sensor needs firmware to be loaded
    # python-validity provides validity-sensors-firmware
    log "Loading sensor firmware (this may take a moment)..."

    # Initialize the sensor - this downloads and installs firmware if needed
    if sudo validity-sensors-firmware; then
        log_success "Sensor firmware initialized"
    else
        log_warn "Firmware initialization returned non-zero (may be already initialized)"
    fi
}

enable_services() {
    log "Enabling and starting services..."

    # Disable the default fprintd service (we use open-fprintd)
    sudo systemctl disable --now fprintd.service 2>/dev/null || true
    sudo systemctl mask fprintd.service 2>/dev/null || true

    # Helper to enable service only if it has an [Install] section
    enable_if_supported() {
        local service="$1"
        if systemctl cat "$service" 2>/dev/null | grep -q '^\[Install\]'; then
            sudo systemctl enable "$service"
        fi
    }

    # Enable python3-validity (the driver service)
    enable_if_supported python3-validity.service
    sudo systemctl start python3-validity.service

    # Enable suspend hotfix for python3-validity
    enable_if_supported python3-validity-suspend-hotfix.service

    # Enable open-fprintd services
    # Note: open-fprintd uses D-Bus activation, so enable may not be needed
    enable_if_supported open-fprintd.service
    sudo systemctl start open-fprintd.service

    enable_if_supported open-fprintd-resume.service
    enable_if_supported open-fprintd-suspend.service

    log_success "Services enabled and started"
}

configure_pam() {
    log "Configuring PAM for fingerprint authentication..."

    local pam_line="auth      sufficient pam_fprintd.so"
    local pam_files=(
        "/etc/pam.d/sudo"
        "/etc/pam.d/system-local-login"
        "/etc/pam.d/polkit-1"
    )

    for pam_file in "${pam_files[@]}"; do
        if [[ -f "$pam_file" ]]; then
            if grep -q "pam_fprintd.so" "$pam_file"; then
                log_warn "PAM already configured in $pam_file"
            else
                # Add fprintd line at the beginning (after any existing auth lines)
                # Only create backup if one doesn't exist (preserve original)
                if [[ ! -f "${pam_file}.bak" ]]; then
                    sudo cp "$pam_file" "${pam_file}.bak"
                fi

                # Insert after #%PAM-1.0 or at the beginning
                if grep -q "^#%PAM" "$pam_file"; then
                    sudo sed -i '/^#%PAM/a auth      sufficient pam_fprintd.so' "$pam_file"
                else
                    echo -e "$pam_line\n$(cat "$pam_file")" | sudo tee "$pam_file" > /dev/null
                fi

                log_success "Configured $pam_file (backup: ${pam_file}.bak)"
            fi
        else
            log_warn "PAM file not found: $pam_file"
        fi
    done
}

enroll_fingerprint() {
    log "Ready to enroll fingerprint..."
    echo ""
    echo "Available fingers to enroll:"
    echo "  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger"
    echo "  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger"
    echo ""

    read -rp "Enter finger to enroll (default: right-index-finger): " finger
    finger=${finger:-right-index-finger}

    log "Place your $finger on the sensor multiple times when prompted..."
    echo ""

    if fprintd-enroll -f "$finger"; then
        log_success "Fingerprint enrolled successfully!"
    else
        log_error "Fingerprint enrollment failed"
        log "You can try again later with: fprintd-enroll -f $finger"
        return 1
    fi
}

verify_fingerprint() {
    log "Verifying enrolled fingerprint..."
    echo "Place your finger on the sensor..."

    if fprintd-verify; then
        log_success "Fingerprint verification successful!"
    else
        log_error "Fingerprint verification failed"
        return 1
    fi
}

show_usage() {
    cat << EOF
Usage: $(basename "$0") [command]

Commands:
  install     Full installation (packages, services, PAM config)
  enroll      Enroll a new fingerprint
  verify      Verify enrolled fingerprint
  list        List enrolled fingerprints
  delete      Delete enrolled fingerprints
  status      Show service status
  help        Show this help message

If no command is given, runs full installation.
EOF
}

cmd_install() {
    check_root
    check_sensor
    check_aur_helper
    install_packages
    initialize_sensor
    enable_services
    configure_pam

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Enroll your fingerprint: $0 enroll"
    echo "  2. Test it: $0 verify"
    echo "  3. Try: sudo echo 'Fingerprint works!'"
    echo ""
}

cmd_enroll() {
    enroll_fingerprint
}

cmd_verify() {
    verify_fingerprint
}

cmd_list() {
    fprintd-list "$USER"
}

cmd_delete() {
    log "Deleting all enrolled fingerprints for $USER..."
    fprintd-delete "$USER"
    log_success "Fingerprints deleted"
}

cmd_status() {
    echo "=== Service Status ==="
    systemctl status python3-validity.service --no-pager || true
    echo ""
    systemctl status open-fprintd.service --no-pager || true
    echo ""
    echo "=== Enrolled Fingerprints ==="
    fprintd-list "$USER" 2>/dev/null || echo "No fingerprints enrolled"
}

main() {
    local cmd="${1:-install}"

    case "$cmd" in
        install)
            cmd_install
            ;;
        enroll)
            cmd_enroll
            ;;
        verify)
            cmd_verify
            ;;
        list)
            cmd_list
            ;;
        delete)
            cmd_delete
            ;;
        status)
            cmd_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $cmd"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"

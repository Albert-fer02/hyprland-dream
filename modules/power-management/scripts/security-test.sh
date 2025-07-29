#!/usr/bin/env bash
# Security Test Script for Hyprland Dream Power Management
# Tests all security and power management features

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_test() {
    echo -n "Testing $1... "
}

print_pass() {
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  Error: $1${NC}"
    ((TESTS_FAILED++))
}

print_warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}

# =============================================================================
# DEPENDENCY TESTS
# =============================================================================

test_dependencies() {
    print_header "Testing Dependencies"
    
    local deps=("swayidle" "swaylock" "systemctl" "notify-send" "playerctl" "pamixer")
    
    for dep in "${deps[@]}"; do
        print_test "$dep"
        if command -v "$dep" >/dev/null 2>&1; then
            print_pass
        else
            print_fail "$dep not found"
        fi
    done
}

# =============================================================================
# SERVICE TESTS
# =============================================================================

test_services() {
    print_header "Testing Systemd Services"
    
    local services=("power-management" "lid-close-handler" "auto-pause-headphones")
    
    for service in "${services[@]}"; do
        print_test "$service.service"
        if systemctl --user is-enabled --quiet "$service.service"; then
            if systemctl --user is-active --quiet "$service.service"; then
                print_pass
            else
                print_fail "$service.service is enabled but not active"
            fi
        else
            print_fail "$service.service is not enabled"
        fi
    done
}

# =============================================================================
# CONFIGURATION TESTS
# =============================================================================

test_configurations() {
    print_header "Testing Configurations"
    
    # Test swaylock config
    print_test "swaylock configuration"
    if [[ -f "$HOME/.config/swaylock/config" ]]; then
        if grep -q "effect-blur" "$HOME/.config/swaylock/config"; then
            print_pass
        else
            print_fail "swaylock config missing blur effect"
        fi
    else
        print_fail "swaylock config not found"
    fi
    
    # Test wlogout config
    print_test "wlogout configuration"
    if [[ -f "$HOME/.config/wlogout/layout.json" ]]; then
        if grep -q "confirm" "$HOME/.config/wlogout/layout.json"; then
            print_pass
        else
            print_fail "wlogout config missing confirmations"
        fi
    else
        print_fail "wlogout config not found"
    fi
    
    # Test logind config
    print_test "systemd logind configuration"
    if [[ -f "/etc/systemd/logind.conf" ]]; then
        if grep -q "HandleLidSwitch" "/etc/systemd/logind.conf"; then
            print_pass
        else
            print_warn "logind config may not be properly configured"
        fi
    else
        print_warn "logind config not found (may need sudo)"
    fi
}

# =============================================================================
# FUNCTIONALITY TESTS
# =============================================================================

test_functionality() {
    print_header "Testing Functionality"
    
    # Test notification system
    print_test "notification system"
    if notify-send --help >/dev/null 2>&1; then
        print_pass
    else
        print_fail "notify-send not working"
    fi
    
    # Test swaylock
    print_test "swaylock functionality"
    if timeout 2 swaylock --help >/dev/null 2>&1; then
        print_pass
    else
        print_fail "swaylock not working"
    fi
    
    # Test wlogout
    print_test "wlogout functionality"
    if timeout 2 wlogout --help >/dev/null 2>&1; then
        print_pass
    else
        print_fail "wlogout not working"
    fi
}

# =============================================================================
# HARDWARE TESTS
# =============================================================================

test_hardware() {
    print_header "Testing Hardware Detection"
    
    # Test laptop detection
    print_test "laptop detection"
    if [[ -f /sys/class/power_supply/BAT* ]]; then
        print_pass
        print_info "Running on laptop"
        
        # Test battery
        print_test "battery detection"
        if [[ -f /sys/class/power_supply/BAT*/capacity ]]; then
            local battery_level=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
            echo -e "${GREEN}PASS${NC} (Battery: ${battery_level}%)"
            ((TESTS_PASSED++))
        else
            print_fail "battery capacity not readable"
        fi
        
        # Test AC detection
        print_test "AC detection"
        if [[ -f /sys/class/power_supply/AC/online ]]; then
            local ac_status=$(cat /sys/class/power_supply/AC/online)
            if [[ "$ac_status" == "1" ]]; then
                echo -e "${GREEN}PASS${NC} (AC connected)"
            else
                echo -e "${GREEN}PASS${NC} (AC disconnected)"
            fi
            ((TESTS_PASSED++))
        else
            print_fail "AC status not readable"
        fi
        
        # Test lid sensor
        print_test "lid sensor"
        if [[ -f /proc/acpi/button/lid/LID0/state ]]; then
            local lid_state=$(cat /proc/acpi/button/lid/LID0/state)
            echo -e "${GREEN}PASS${NC} (Lid: $lid_state)"
            ((TESTS_PASSED++))
        else
            print_warn "lid sensor not found"
        fi
    else
        print_pass
        print_info "Running on desktop"
    fi
}

# =============================================================================
# SECURITY TESTS
# =============================================================================

test_security() {
    print_header "Testing Security Features"
    
    # Test script permissions
    print_test "script permissions"
    local scripts=(
        "$HOME/.config/hyprland-dream/modules/power-management/scripts/power-management.sh"
        "$HOME/.config/hyprland-dream/modules/power-management/scripts/lid-close-handler.sh"
    )
    
    local all_executable=true
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ ! -x "$script" ]]; then
                all_executable=false
                break
            fi
        else
            all_executable=false
            break
        fi
    done
    
    if $all_executable; then
        print_pass
    else
        print_fail "some scripts are not executable"
    fi
    
    # Test log directory
    print_test "log directory"
    if [[ -d "$HOME/.local/share/hyprland-dream" ]]; then
        print_pass
    else
        print_warn "log directory not found"
    fi
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

test_integration() {
    print_header "Testing Integration"
    
    # Test Hyprland keybinds
    print_test "Hyprland keybinds"
    if [[ -f "$HOME/.config/hyprland-dream/modules/hypr/config/keybinds.conf" ]]; then
        if grep -q "swaylock" "$HOME/.config/hyprland-dream/modules/hypr/config/keybinds.conf"; then
            print_pass
        else
            print_fail "swaylock keybinds not found in Hyprland config"
        fi
    else
        print_warn "Hyprland config not found"
    fi
    
    # Test systemd user services directory
    print_test "systemd user services"
    if [[ -d "$HOME/.config/systemd/user" ]]; then
        local service_files=(
            "$HOME/.config/systemd/user/power-management.service"
            "$HOME/.config/systemd/user/lid-close-handler.service"
        )
        
        local all_services_exist=true
        for service in "${service_files[@]}"; do
            if [[ ! -f "$service" ]]; then
                all_services_exist=false
                break
            fi
        done
        
        if $all_services_exist; then
            print_pass
        else
            print_fail "some systemd services not found"
        fi
    else
        print_fail "systemd user directory not found"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Hyprland Dream Security Test  ${NC}"
    echo -e "${BLUE}================================${NC}"
    
    # Run all tests
    test_dependencies
    test_services
    test_configurations
    test_functionality
    test_hardware
    test_security
    test_integration
    
    # Print summary
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}           SUMMARY              ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    if [[ $total_tests -gt 0 ]]; then
        local success_rate=$((TESTS_PASSED * 100 / total_tests))
        echo -e "Success Rate: ${BLUE}${success_rate}%${NC}"
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}✅ All tests passed! Security system is working correctly.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed. Please check the errors above.${NC}"
        exit 1
    fi
}

# Only run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
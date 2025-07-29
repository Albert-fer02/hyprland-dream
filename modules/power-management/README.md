# Enhanced Power Management Module

A comprehensive security and power management system for Hyprland Dream, featuring intelligent energy management, automatic locking, lid close handling, and enhanced security features.

## Features

### 🔒 Security Features
- **Automatic Screen Locking**: Configurable timeouts for inactivity
- **Session Timeout**: Force logout after extended inactivity
- **Enhanced Swaylock**: Blur effects, visual indicators, and security feedback
- **Quick Lock Shortcuts**: Multiple keybind options for immediate locking

### ⚡ Power Management
- **Intelligent Suspend**: Auto-suspend with battery monitoring
- **Lid Close Handling**: Automatic lock and suspend on laptop lid close
- **Battery Monitoring**: Low battery warnings and critical battery actions
- **AC/Battery Detection**: Different behavior based on power source

### 🎯 User Experience
- **Visual Feedback**: Notifications for all power events
- **Smooth Animations**: Enhanced wlogout with modern design
- **Confirmation Dialogs**: Security confirmations for critical actions
- **Responsive Design**: Works on both desktop and laptop systems

## Components

### Scripts
- `power-management.sh`: Main power management script with intelligent features
- `lid-close-handler.sh`: Dedicated lid close event handler for laptops

### Systemd Services
- `power-management.service`: Main power management service
- `lid-close-handler.service`: Lid close monitoring service
- `auto-pause-headphones.service`: Audio device management

### Configuration
- `logind.conf`: Systemd logind configuration for power events
- Enhanced swaylock configuration with security features
- Modern wlogout layout with confirmations

## Installation

### Full Installation
```bash
cd modules/power-management
./install.sh
```
Select option 1 for complete installation with packages and configuration.

### Configuration Only
```bash
cd modules/power-management
./install.sh
```
Select option 2 to copy configuration only.

## Configuration

### Timeouts (Configurable in `power-management.sh`)
```bash
INACTIVITY_LOCK=300      # 5 minutes - Lock screen
INACTIVITY_SUSPEND=900   # 15 minutes - Suspend
INACTIVITY_LOGOUT=3600   # 1 hour - Force logout
SESSION_TIMEOUT=7200     # 2 hours - Session timeout
```

### Battery Thresholds
```bash
BATTERY_LOW=20          # Low battery warning
BATTERY_CRITICAL=10     # Critical battery action
```

### Keybinds (Hyprland)
- `SUPER + L`: Lock screen
- `SUPER + X`: Open logout menu
- `SUPER + ESCAPE`: Quick lock with notification
- `SUPER + SHIFT + L`: Lock and suspend
- `SUPER + SHIFT + X`: Force logout
- `SUPER + SHIFT + R`: Reboot
- `SUPER + SHIFT + S`: Shutdown

## Features in Detail

### Enhanced Swaylock
- **Blur Effects**: 10x7 blur with scaling
- **Visual Indicators**: Clock, battery, and status indicators
- **Security Features**: Failed attempt tracking, grace periods
- **Systemd Integration**: Automatic lock on suspend/resume

### Modern Wlogout
- **Elegant Design**: Gradient backgrounds and smooth animations
- **Security Confirmations**: Confirmation dialogs for critical actions
- **Visual Feedback**: Hover effects and button animations
- **Responsive Layout**: Works on different screen sizes

### Intelligent Power Management
- **Battery Monitoring**: Real-time battery level tracking
- **AC Detection**: Different behavior when plugged in
- **Lid Close Handling**: Automatic actions on laptop lid close
- **Pre/Post Hooks**: Customizable actions before/after suspend

### Systemd Integration
- **User Services**: Runs as user services for better security
- **Automatic Restart**: Services restart on failure
- **Logging**: Comprehensive logging for debugging
- **Dependencies**: Proper dependency management

## Logging

Logs are stored in:
- Power Management: `~/.local/share/hyprland-dream/power-management.log`
- Lid Handler: `~/.local/share/hyprland-dream/lid-handler.log`

## Troubleshooting

### Check Service Status
```bash
systemctl --user status power-management.service
systemctl --user status lid-close-handler.service
```

### View Logs
```bash
journalctl --user -u power-management.service -f
journalctl --user -u lid-close-handler.service -f
```

### Manual Testing
```bash
# Test power management script
~/.config/hyprland-dream/modules/power-management/scripts/power-management.sh

# Test lid close handler
~/.config/hyprland-dream/modules/power-management/scripts/lid-close-handler.sh
```

### Common Issues

1. **Services not starting**: Check dependencies are installed
2. **Lid close not working**: Verify laptop has lid sensor
3. **Battery monitoring issues**: Check battery sysfs files exist
4. **Permission errors**: Ensure scripts are executable

## Customization

### Adding Custom Pre/Post Suspend Actions
Edit `power-management.sh` and modify the `pre_suspend_hooks()` and `post_suspend_hooks()` functions.

### Modifying Timeouts
Edit the timeout variables at the top of `power-management.sh`.

### Custom Keybinds
Add your custom keybinds to `modules/hypr/config/keybinds.conf`.

## Dependencies

- `swayidle`: Idle detection and timeout management
- `swaylock`: Screen locking
- `playerctl`: Media player control
- `pamixer`: Audio control
- `systemd`: Service management
- `notify-send`: Desktop notifications

## Security Considerations

- All scripts run with user privileges
- Systemd services have security restrictions
- Logind configuration requires sudo for system-wide changes
- Sensitive operations require confirmation
- Automatic logout prevents session hijacking

## Contributing

When contributing to this module:
1. Follow the existing code style
2. Add proper error handling
3. Include logging for debugging
4. Test on both desktop and laptop systems
5. Update documentation for new features

## License

This module is part of Hyprland Dream and follows the same license terms. 
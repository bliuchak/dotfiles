# dotfiles

dotfiles

```bash
stow -t ~/ tmux
stow -t ~/.local/bin scripts
stow -t ~/.config systemd
```

## bt-auto-switch

Auto-switches default audio sink/source to Bluetooth when a device connects. Uses dbus-monitor to watch BlueZ connection events and wpctl (WirePlumber) to set defaults.

**Usage:**
- `bt-auto-switch.sh monitor` - Continuously monitor for BT connections (default)
- `bt-auto-switch.sh switch` - One-shot switch to Bluetooth if available

**Systemd service:**
```bash
systemctl --user enable --now bt-auto-switch.service
```

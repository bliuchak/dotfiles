# dotfiles

dotfiles

```bash
stow -t ~/ tmux
stow -t ~/.local/bin scripts
stow -t ~/ bt-auto-switch
sudo stow -t / bt-reconnect # system-level service due to sleep.target
```

## Extra Steps

```bash
systemctl --user daemon-reload
systemctl --user enable --now bt-auto-switch.service

sudo systemctl daemon-reload
sudo systemctl enable bt-reconnect.service
```

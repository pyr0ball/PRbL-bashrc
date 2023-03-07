# Pyr0ball's Reductive [bash] Library Auto-Installer

---

This installer depends on [PRbL](https://github.com/pyr0ball/PRbL-bashrc.git) and should be cloned recursively:

```bash
git clone --recurse-submodules https://github.com/pyr0ball/PRbL-bashrc.git
cd PRbL-bashrc/
./install.sh -i
```

This installer sets up a number of bash-enhancing features:

- Easy access to easy-to-use functions in bash scripting (check out ./PRbL/demo.sh for details)
- A pluggable environment configuration via ~/.bashrc.d/
- An informative terminal login splash page

Currently this installer only handles debian/ubuntu-based distros.

Planned features:

- Expanded automatic OS detection and package handling
- Modular login splash page

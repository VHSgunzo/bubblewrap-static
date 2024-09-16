# [bubblewrap-static](https://github.com/VHSgunzo/bubblewrap-static/releases/latest)

* Statically compiled [bubblewrap](https://github.com/containers/bubblewrap), an Unprivileged sandboxing tool for use in [runimage](https://github.com/VHSgunzo/runimage)
* Check [Releases](https://github.com/VHSgunzo/bubblewrap-static/releases/latest) for `x86_64-Linux` & `aarch64-Linux` PreCompiled Binaries: https://github.com/VHSgunzo/bubblewrap-static/releases/latest
- #### To Build it on your Own:
```bash
!#The script assumes Ubuntu with sudo installed (preferably configured as passwordless sudo) 
git clone --filter="blob:none" "https://github.com/VHSgunzo/bubblewrap-static.git"
cd "./bubblewrap-static" && chmod +x "./build_on_nix.sh" && "./build_on_nix.sh"

!# If you don't have Ubuntu, It is also possible to build this on a Ubuntu-Chroot or Docker
!# But you may run into: error: unable to load seccomp BPF program: Invalid argument
!# To fix this:
sed 's/bash -s -- install linux --init none --no-confirm/bash -s -- install linux --init none --extra-conf "filter-syscalls = false" --no-confirm/g' -i "./build_on_nix.sh"
!# And then re-run the script
!# More Details: https://github.com/DeterminateSystems/nix-installer/issues/324
```
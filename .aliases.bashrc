#!/bin/bash

alias sudo='sudo -s'

alias battery-conservation-on='sudo systemctl enable --now battery-conservation'
alias battery-conservation-off='sudo systemctl disable --now battery-conservation'
alias rapid-charge-on='sudo systemctl enable --now rapid-charge'
alias rapid-charge-off='sudo systemctl disable --now rapid-charge'
alias charging-status='printf "rapid-charge is "; systemctl is-enabled rapid-charge; printf "and "; systemctl is-active rapid-charge; printf "battery-conservation is "; systemctl is-enabled battery-conservation; printf "and "; systemctl is-active battery-conservation;'

alias gctest='for i in *.c; do gcc $i -o ${i%.c}; chmod +x ${i%.c}; done; for i in *.c; do echo -e "\ntesting: ${i%.c}"; ./${i%.c}; done'
alias gcltest='for i in *.c; do gcc $i -o ${i%.c}; chmod +x ${i%.c}; done; for i in *.c; do echo -e "\ntesting: ${i%.c}"; loop ./${i%.c}; done'

alias autopurge='(list="$(pacman -Qdtq)" && yay -Rcns ${list//$'\n'/ } || echo "there'\''s probably nothing to purge")'

alias s-sync='phsync -d /sdcard/school/ /home/misc/work/school/'

alias gpgit='git config commit.gpgsign true'

alias ghc='ghc -no-keep-hi-files -no-keep-o-files'

# alias npm=pnpm
alias matlab='LD_LIBRARY_PATH=//home/misc/bin/MATLAB/R2022b//bin/glnxa64/:/opt/rocm/lib:/opt/rocm/lib64:/opt/rocm/profiler/lib:/opt/rocm/profiler/lib64:/opt/rocm/opencl/lib:/opt/rocm/hip/lib:/opt/rocm/opencl/lib64:/opt/rocm/hip/lib64 matlab'

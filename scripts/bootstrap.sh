#! /bin/bash

set -uexo pipefail
export DEBIAN_FRONTEND=noninteractive


if [ ! -f "/etc/apt/sources.list.bak" ]; then

# config repo and upgrade
cp /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list << EOF
# stable
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free

# testing
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ testing main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ testing main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ testing-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ testing-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security testing-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security testing-security main contrib non-free

# sid
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
EOF
cat > /etc/apt/preferences.d/my_preferences << EOF
Package: *
Pin: release a=stable
Pin-Priority: 700

Package: *
Pin: release a=testing
Pin-Priority: 650

Package: *
Pin: release a=unstable
Pin-Priority: 600
EOF
apt -y update
apt -y dist-upgrade

else

apt -y update

fi

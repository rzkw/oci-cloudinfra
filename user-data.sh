#!/bin/bash
set -euo pipefail

# CIS Ubuntu 24.04 LTS Level 1 Server Hardening + A1 Bootstrap
# Combines CIS L1 hardening first, then instance bootstrap (Docker rootless,
# Node.js, OCI CLI, gh, ansible-core).
#
# CIS L1 references:
#   - CIS Ubuntu Linux 24.04 LTS Benchmark v1.0.0
#   - https://docs.cloud-init.io/en/latest/explanation/hardening.html
#   - https://github.com/oci-landing-zones/oci-cis-landingzone-quickstart
#
# ponytail: ~23KB base64, OCI limit is 32KB. If this grows, switch to
# cloud-init's #include format hosting the two scripts separately.

# =============================================================================
# Part 1: CIS L1 Server Hardening
# =============================================================================

LOG=/var/log/cis-l1-hardening.log
SSH_ALLOW_IP=103.154.138.8
SSH_PORT=22
VM_USER=ubuntu

log() {
  local msg
  msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "$LOG"
}

log_section() {
  log ""
  log "=== $* ==="
}

run() {
  if "$@" >> "$LOG" 2>&1; then
    log "  [OK] $*"
  else
    local rc=$?
    log "  [WARN] command exited $rc: $*"
  fi
}

sysctl_apply() {
  sysctl -w "$1=$2" >> "$LOG" 2>&1 || true
  if grep -q "^${1}\s*=" /etc/sysctl.d/99-cis.conf 2>/dev/null; then
    sed -i "s|^${1}\s*=.*|${1} = ${2}|" /etc/sysctl.d/99-cis.conf
  else
    echo "${1} = ${2}" >> /etc/sysctl.d/99-cis.conf
  fi
}

add_sysctl_conf() {
  local file=/etc/sysctl.d/99-cis.conf
  mkdir -p /etc/sysctl.d
  [ -f "$file" ] || touch "$file"
}

# ---- 1.1.1: Disable unused filesystem kernel modules ----
log_section "1.1.1 Disable unused filesystem kernel modules"

for mod in cramfs freevxfs hfs hfsplus jffs2 squashfs udf usb-storage overlayfs; do
  if modinfo "$mod" &>/dev/null; then
    conf="/etc/modprobe.d/${mod}.conf"
    bin_false=$(readlink -f /bin/false)

    if ! grep -qE "^\s*install\s+${mod}\s+" "$conf" 2>/dev/null; then
      echo "install ${mod} ${bin_false}" >> "$conf"
      log "  [OK] Module ${mod}: install directive added"
    fi
    if ! grep -qE "^\s*blacklist\s+${mod}" "$conf" 2>/dev/null; then
      echo "blacklist ${mod}" >> "$conf"
      log "  [OK] Module ${mod}: blacklist added"
    fi
    rmmod "$mod" 2>/dev/null || log "  [SKIP] Module ${mod}: could not unload (in use or built-in)"
  fi
done

# ---- 1.1.2: Mount option hardening ----
log_section "1.1.2 Configure filesystem mount options"

apply_mount_opt() {
  local mount="$1"
  local opts="$2"
  local desc="$3"

  if grep -qE "[[:space:]]${mount}[[:space:]]" /etc/fstab; then
    if ! grep -E "[[:space:]]${mount}[[:space:]]" /etc/fstab | head -1 | grep -qE "[, ]${opts}[, ]"; then
      awk -v mp="$mount" -v opt="$opts" '
        $2 == mp {
          if ($4 !~ opt) $4 = $4 "," opt
        }
        { print }
      ' /etc/fstab > /etc/fstab.tmp && mv /etc/fstab.tmp /etc/fstab
      log "  [OK] ${desc}"
    else
      log "  [SKIP] ${desc}: already set"
    fi
  else
    log "  [SKIP] ${desc}: ${mount} not in /etc/fstab"
  fi
}

apply_mount_opt "/tmp" "nodev" "1.1.2.1.2 nodev on /tmp"
apply_mount_opt "/tmp" "nosuid" "1.1.2.1.3 nosuid on /tmp"
apply_mount_opt "/tmp" "noexec" "1.1.2.1.4 noexec on /tmp"
apply_mount_opt "/dev/shm" "nodev" "1.1.2.2.2 nodev on /dev/shm"
apply_mount_opt "/dev/shm" "nosuid" "1.1.2.2.3 nosuid on /dev/shm"
apply_mount_opt "/dev/shm" "noexec" "1.1.2.2.4 noexec on /dev/shm"
apply_mount_opt "/home" "nodev" "1.1.2.3.2 nodev on /home"
apply_mount_opt "/home" "nosuid" "1.1.2.3.3 nosuid on /home"
apply_mount_opt "/var" "nodev" "1.1.2.4.2 nodev on /var"
apply_mount_opt "/var" "nosuid" "1.1.2.4.3 nosuid on /var"
apply_mount_opt "/var/tmp" "nodev" "1.1.2.5.2 nodev on /var/tmp"
apply_mount_opt "/var/tmp" "nosuid" "1.1.2.5.3 nosuid on /var/tmp"
apply_mount_opt "/var/tmp" "noexec" "1.1.2.5.4 noexec on /var/tmp"
log "  [NOTE] Remount partitions from fstab to apply: mount -a"

# ---- 1.2: Package updates ----
log_section "1.2.2.1 Apply package updates"
run apt-get update -y
run apt-get upgrade -y

# ---- 1.3: AppArmor ----
log_section "1.3.1 AppArmor"

run apt-get install -y apparmor apparmor-utils

if ! grep -q "apparmor=1" /etc/default/grub 2>/dev/null; then
  sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor /' /etc/default/grub
  run update-grub
  log "  [OK] 1.3.1.2 AppArmor enabled in GRUB"
else
  log "  [SKIP] 1.3.1.2 AppArmor already in GRUB"
fi

if command -v aa-enforce &>/dev/null; then
  run aa-enforce /etc/apparmor.d/*
  log "  [OK] 1.3.1.3 AppArmor profiles set to enforce"
fi

# ---- 1.4: Bootloader ----
log_section "1.4 Bootloader configuration"

run chown root:root /boot/grub/grub.cfg
run chmod 600 /boot/grub/grub.cfg

# ---- 1.5: Process hardening ----
log_section "1.5 Process hardening"

add_sysctl_conf
sysctl_apply kernel.randomize_va_space 2
log "  [OK] 1.5.1 ASLR enabled"

sysctl_apply kernel.yama.ptrace_scope 1
log "  [OK] 1.5.2 ptrace_scope restricted"

mkdir -p /etc/security/limits.d
if ! grep -q "^\*\s+hard\s+core\s+0" /etc/security/limits.d/99-cis.conf 2>/dev/null; then
  echo "* hard core 0" >> /etc/security/limits.d/99-cis.conf
fi
sysctl_apply fs.suid_dumpable 0
log "  [OK] 1.5.3 Core dumps restricted"

if [ -f /etc/systemd/coredump.conf ]; then
  sed -i 's/^#*Storage=.*/Storage=none/' /etc/systemd/coredump.conf
  sed -i 's/^#*ProcessSizeMax=.*/ProcessSizeMax=0/' /etc/systemd/coredump.conf
  run systemctl daemon-reload
fi

if dpkg -l | grep -qw prelink; then
  run prelink -ua
  run apt-get purge -y prelink
  log "  [OK] 1.5.4 prelink removed"
else
  log "  [SKIP] 1.5.4 prelink not installed"
fi

if dpkg -l | grep -qw apport; then
  sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport 2>/dev/null || echo "enabled=0" >> /etc/default/apport
  run systemctl stop apport 2>/dev/null || true
  run systemctl mask apport 2>/dev/null || true
  run apt-get purge -y apport
  log "  [OK] 1.5.5 apport disabled and removed"
else
  log "  [SKIP] 1.5.5 apport not installed"
fi

# ---- 1.6: Warning banners ----
log_section "1.6 Warning banners"

BANNER="*****************************************************************
*                           NOTICE                                  *
*                                                                    *
* This system is for authorized use only. All activities are         *
* monitored and logged. Unauthorized access is prohibited.           *
*****************************************************************"

echo "$BANNER" > /etc/issue
echo "$BANNER" > /etc/issue.net
cat /dev/null > /etc/motd 2>/dev/null || true

chown root:root /etc/issue /etc/issue.net
chmod 644 /etc/issue /etc/issue.net
log "  [OK] 1.6 Warning banners configured"

# ---- 1.7: Remove GDM ----
log_section "1.7 Remove GDM (no GUI server)"

if dpkg -l | grep -qw gdm3; then
  run apt-get purge -y gdm3
  run apt-get autoremove -y
  log "  [OK] 1.7.1 GDM removed"
else
  log "  [SKIP] 1.7.1 GDM not installed"
fi

# ---- 2.1: Remove/disable unused services ----
log_section "2.1 Remove and disable unused services"

SERVICES_REMOVE=(
  autofs avahi-daemon isc-dhcp-server bind9 dnsmasq smbd vsftpd dovecot-core
  nfs-kernel-server ypserv cups rpcbind rsync snmpd telnetd tftpd-hpa squid
  apache2 xinetd xserver-common postfix
)

for pkg in "${SERVICES_REMOVE[@]}"; do
  if dpkg -l | grep -qw "$pkg"; then
    run apt-get purge -y "$pkg"
  fi
done

for svc in autofs avahi-daemon dhcpd bind9 dnsmasq smbd vsftpd dovecot \
           nfs-server ypserv cups-browsed cups rpcbind rsync snmpd \
           squid apache2 xinetd postfix; do
  run systemctl stop "$svc" 2>/dev/null || true
  run systemctl disable "$svc" 2>/dev/null || true
  run systemctl mask "$svc" 2>/dev/null || true
done

# ---- 2.2: Remove client tools ----
log_section "2.2 Remove unused client tools"

CLIENTS_REMOVE=(nis rsh-client talk telnet ldap-utils ftp)
for pkg in "${CLIENTS_REMOVE[@]}"; do
  if dpkg -l | grep -qw "$pkg"; then
    run apt-get purge -y "$pkg"
  fi
done
run apt-get autoremove -y

# ---- 2.3: Time sync ----
log_section "2.3 Configure time synchronization"

run apt-get install -y systemd-timesyncd
run systemctl enable systemd-timesyncd

if [ -f /etc/systemd/timesyncd.conf ]; then
  sed -i 's/^#*NTP=.*/NTP=0.pool.ntp.org 1.pool.ntp.org/' /etc/systemd/timesyncd.conf
  sed -i 's/^#*FallbackNTP=.*/FallbackNTP=ntp.ubuntu.com/' /etc/systemd/timesyncd.conf
fi
run systemctl restart systemd-timesyncd
log "  [OK] 2.3 systemd-timesyncd configured"

# ---- 2.4: Job scheduling ----
log_section "2.4 Configure job scheduling"

CRON_PATHS=(/etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d)
for p in "${CRON_PATHS[@]}"; do
  if [ -e "$p" ]; then
    chown root:root "$p"
    chmod og-rwx "$p"
  fi
done
touch /etc/cron.allow
chown root:root /etc/cron.allow
chmod 640 /etc/cron.allow
[ -f /etc/cron.deny ] && chmod 640 /etc/cron.deny
log "  [OK] 2.4 cron configured"

# ---- 3.1: Disable wireless and bluetooth ----
log_section "3.1 Disable wireless and bluetooth"

run systemctl stop bluetooth 2>/dev/null || true
run systemctl mask bluetooth 2>/dev/null || true
if dpkg -l | grep -qw bluez; then
  run apt-get purge -y bluez
fi
log "  [OK] 3.1 Bluetooth disabled"

# ---- 3.2: Kernel sysctl hardening ----
log_section "3.2 Kernel parameter hardening"

add_sysctl_conf

sysctl_apply net.ipv4.ip_forward 0
sysctl_apply net.ipv4.conf.all.send_redirects 0
sysctl_apply net.ipv4.conf.default.send_redirects 0
sysctl_apply net.ipv4.conf.all.accept_source_route 0
sysctl_apply net.ipv4.conf.default.accept_source_route 0
sysctl_apply net.ipv4.conf.all.accept_redirects 0
sysctl_apply net.ipv4.conf.default.accept_redirects 0
sysctl_apply net.ipv4.conf.all.secure_redirects 0
sysctl_apply net.ipv4.conf.default.secure_redirects 0
sysctl_apply net.ipv4.conf.all.log_martians 1
sysctl_apply net.ipv4.conf.default.log_martians 1
sysctl_apply net.ipv4.icmp_echo_ignore_broadcasts 1
sysctl_apply net.ipv4.icmp_ignore_bogus_error_responses 1
sysctl_apply net.ipv4.conf.all.rp_filter 1
sysctl_apply net.ipv4.conf.default.rp_filter 1
sysctl_apply net.ipv4.tcp_syncookies 1
sysctl_apply net.ipv6.conf.all.accept_ra 0
sysctl_apply net.ipv6.conf.default.accept_ra 0
sysctl_apply net.ipv6.conf.all.accept_redirects 0
sysctl_apply net.ipv6.conf.default.accept_redirects 0

run sysctl -p /etc/sysctl.d/99-cis.conf
log "  [OK] 3.2 Kernel parameters hardened"

# ---- 3.3: Firewall ----
log_section "3.3 Configure UFW firewall"

run apt-get install -y ufw

ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1
ufw allow from "$SSH_ALLOW_IP" to any port "$SSH_PORT" proto tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
log "  [OK] 3.3 UFW: SSH from ${SSH_ALLOW_IP} only, all else denied"

# ---- 4.1: Auditd ----
log_section "4.1 Configure auditd"

run apt-get install -y auditd audispd-plugins

# Use CIS L1 recommended rules from Ubuntu 24.04
AUDIT_RULES=/etc/audit/rules.d/99-cis.rules
mkdir -p /etc/audit/rules.d

cat > "$AUDIT_RULES" << 'RULEOF'
# CIS 4.1.1 - Audit time changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change

# CIS 4.1.2 - Audit user/group changes
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# CIS 4.1.3 - Audit network environment
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/networks -p wa -k system-locale

# CIS 4.1.4 - Audit login/logout
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p wa -k logins

# CIS 4.1.5 - Audit session initiation
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session

# CIS 4.1.6 - Audit discretionary access control
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod

# CIS 4.1.7 - Audit unsuccessful file access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access

# CIS 4.1.8 - Audit privileged commands
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k priv_cmd
-a always,exit -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k priv_cmd

# CIS 4.1.9 - Audit module loading/unloading
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules
-a always,exit -F arch=b32 -S init_module -S delete_module -k modules

# Make immutable
-e 2
RULEOF

chmod 600 "$AUDIT_RULES"
run augenrules --load 2>/dev/null || true
run systemctl enable auditd
run systemctl restart auditd
log "  [OK] 4.1 auditd configured with CIS L1 rules"

# ---- 4.2: Configure logging ----
log_section "4.2 Configure logging"

run apt-get install -y rsyslog
run systemctl enable rsyslog
run systemctl restart rsyslog
log "  [OK] 4.2 rsyslog enabled"

# ---- 4.3: Log rotation ----
log_section "4.3 Configure log rotation"

if [ -f /etc/logrotate.conf ]; then
  sed -i 's/^#*rotate [0-9]*/rotate 30/' /etc/logrotate.conf
  sed -i 's/^#*weekly/weekly/' /etc/logrotate.conf
  log "  [OK] 4.3 logrotate configured: weekly, keep 30"
fi

# ---- 5.2: Sudo ----
log_section "5.2 Configure sudo"

if dpkg -l | grep -qw sudo; then
  run chmod 750 /etc/sudoers.d
  run chmod 440 /etc/sudoers
  run chown root:root /etc/sudoers /etc/sudoers.d
  log "  [OK] 5.2 sudo permissions configured"
fi

# ---- 5.3: SSH configuration ----
log_section "5.3 SSH server configuration"

SSHD_CONFIG=/etc/ssh/sshd_config.d/99-cis.conf
cat > "$SSHD_CONFIG" << SSHEOF
# CIS L1 Server + custom hardening
Protocol 2
PubkeyAuthentication yes
PubkeyAuthOptions touch-required
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 20
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers $VM_USER
LogLevel VERBOSE
X11Forwarding no
AllowTcpForwarding yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

chmod 600 "$SSHD_CONFIG"
run systemctl restart sshd
log "  [OK] 5.3 SSH hardened: key-only, touch-required, ${SSH_ALLOW_IP} only via UFW"

# ---- 6.1: System file permissions ----
log_section "6.1 System file permissions"

run chmod 644 /etc/passwd
run chown root:root /etc/passwd
run chmod 640 /etc/shadow
run chown root:shadow /etc/shadow
run chmod 640 /etc/gshadow
run chown root:shadow /etc/gshadow
run chmod 644 /etc/group
run chown root:root /etc/group

log ""
log "========================================"
log "  CIS L1 hardening complete"
log "  See $LOG for details"
log "========================================"

# =============================================================================
# Part 2: A1 Instance Bootstrap
# =============================================================================
# Installs: Docker (rootless), git, Node.js, OCI CLI, ansible-core, gh, opencode

export DEBIAN_FRONTEND=noninteractive

# --- SSH authorized key (OCI rejects sk- keys via metadata) ---
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
echo "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIISexvwI8oLz8pjXhleHklOreCoaV2LrQCsUUd/jojizAAAAC3NzaDpkZXYtYm94 dev-box" >> /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

apt-get update -y
apt-get upgrade -y

apt-get install -y \
    curl \
    wget \
    ca-certificates \
    gnupg \
    uidmap \
    dbus-user-session \
    python3-pip \
    python3-venv \
    git

# --- Docker CE + rootless ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

loginctl enable-linger ubuntu

runuser -u ubuntu -- sh -c "
    export PATH=/usr/bin:\$PATH
    dockerd-rootless-setuptool.sh install --force
"

echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock' >> /home/ubuntu/.bashrc

# --- Node.js 22 LTS ---
curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/nodesetup.sh
bash /tmp/nodesetup.sh
apt-get install -y nodejs

# --- OCI CLI ---
curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh -o /tmp/oci-install.sh
chmod +x /tmp/oci-install.sh
runuser -u ubuntu -- /tmp/oci-install.sh --accept-all-defaults

# --- GitHub CLI ---
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /usr/share/keyrings/githubcli-archive-keyring.gpg
chmod a+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt-get update -y
apt-get install -y gh

# --- Ansible-core ---
pip3 install ansible-core

# --- OpenCode ---
npm install -g @opencode/opencode

# --- Verify ---
echo ""
echo "=== Installation verification ==="
echo "git:      $(git --version 2>&1)"
echo "Docker:   $(runuser -u ubuntu -- docker --version 2>&1)"
echo "Node.js:  $(node --version 2>&1)"
echo "npm:      $(npm --version 2>&1)"
echo "gh:       $(gh --version 2>&1 | head -1)"
echo "ansible:  $(ansible --version 2>&1 | head -1)"
echo "oci:      $(oci --version 2>&1)"
echo "opencode: $(opencode --version 2>&1)"
echo ""
echo "=== Bootstrap complete ==="

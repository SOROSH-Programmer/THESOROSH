#!/bin/bash

# ==============================
#        SOROSH PROGRAMMER
# ==============================

# رنگ‌ها
PURPLE="\e[35m"
RESET="\e[0m"

# لوگو S بزرگ
echo -e "${PURPLE}"
echo "  ██████  "
echo " ██       "
echo "  █████   "
echo "      ██  "
echo " ██████   "
echo -e "${RESET}"
echo -e "${PURPLE}=== SOROSH Programmer Firewall ===${RESET}"
echo

# بررسی اجرا با دسترسی root
if [[ $EUID -ne 0 ]]; then
   echo "Please run as root"
   exit 1
fi

echo "Installing required packages..."
apt update -y >/dev/null 2>&1
apt install -y ipset iptables-persistent curl >/dev/null 2>&1

echo "Creating temporary ipset..."
ipset create iran_new hash:net maxelem 200000 2>/dev/null

echo "Downloading Iran IP ranges..."
curl -s https://www.ipdeny.com/ipblocks/data/countries/ir.zone -o /tmp/ir.zone

echo "Adding IP ranges..."
while read ip; do
    ipset add iran_new $ip 2>/dev/null
done < /tmp/ir.zone

echo "Swapping ipset safely..."
ipset create iran hash:net maxelem 200000 -exist
ipset swap iran iran_new
ipset destroy iran_new

echo "Configuring firewall rules..."

# اجازه اتصال‌های فعال
iptables -C OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -I OUTPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# اجازه Reality 443 TCP/UDP
iptables -C OUTPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || \
iptables -I OUTPUT 2 -p tcp --dport 443 -j ACCEPT

iptables -C OUTPUT -p udp --dport 443 -j ACCEPT 2>/dev/null || \
iptables -I OUTPUT 3 -p udp --dport 443 -j ACCEPT

# بلاک NEW connection به ایران
iptables -C OUTPUT -m set --match-set iran dst -m conntrack --ctstate NEW -j REJECT 2>/dev/null || \
iptables -A OUTPUT -m set --match-set iran dst -m conntrack --ctstate NEW -j REJECT

echo "Saving rules..."
netfilter-persistent save >/dev/null 2>&1

echo "----------------------------------------"
echo " SOROSH Programmer Firewall Active ✅"
echo " Iran IPs Blocked | Reality Safe"
echo "----------------------------------------"

#!/bin/bash

echo "========== SOROSH Programmer =========="

apt update -y >/dev/null 2>&1
apt install -y ipset iptables-persistent curl >/dev/null 2>&1

ipset create iran_new hash:net maxelem 200000 2>/dev/null

curl -s https://www.ipdeny.com/ipblocks/data/countries/ir.zone -o /tmp/ir.zone

while read ip; do
    ipset add iran_new $ip 2>/dev/null
done < /tmp/ir.zone

ipset create iran hash:net maxelem 200000 -exist
ipset swap iran iran_new
ipset destroy iran_new

iptables -C OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -I OUTPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -C OUTPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || \
iptables -I OUTPUT 2 -p tcp --dport 443 -j ACCEPT

iptables -C OUTPUT -p udp --dport 443 -j ACCEPT 2>/dev/null || \
iptables -I OUTPUT 3 -p udp --dport 443 -j ACCEPT

iptables -C OUTPUT -m set --match-set iran dst -m conntrack --ctstate NEW -j REJECT 2>/dev/null || \
iptables -A OUTPUT -m set --match-set iran dst -m conntrack --ctstate NEW -j REJECT

netfilter-persistent save >/dev/null 2>&1

echo "----------------------------------------"
echo "SOROSH Programmer Firewall Active ✅"
echo "Iran IPs Blocked | Reality Safe"
echo "----------------------------------------"

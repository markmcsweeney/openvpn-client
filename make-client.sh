#!/usr/bin/env bash
#

set -e

# Find IP Address
SERVER_IP=$(curl -s whatismyip.akamai.com)
if [[ -z "${SERVER_IP}" ]]; then
    SERVER_IP=$(ip a | awk -F"[ /]+" '/global/ && !/127.0/ {print $3; exit}')
fi

read -p "Enter desired client name: " USER

mkdir -p $USER

FILE="$USER/$USER.ovpn"

# Generate Client Config
openssl genrsa -out $USER/$USER-key.pem 2048 > /dev/null 2>&1
chmod 600 $USER/$USER-key.pem
openssl req -new -key $USER/$USER-key.pem -out $USER/$USER-csr.pem -subj /CN=$USER/ > /dev/null 2>&1
openssl x509 -req -in $USER/$USER-csr.pem -out $USER/$USER-cert.pem -CA /etc/openvpn/ca.pem -CAkey /etc/openvpn/ca-key.pem -days 36525 > /dev/null 2>&1

cat > $FILE <<EOF
client
nobind
dev tun
redirect-gateway def1 bypass-dhcp
remote $SERVER_IP 1194 udp
comp-lzo yes

<ca>
$(cat /etc/openvpn/ca.pem)
</ca>
<cert>
$(cat $USER/$USER-cert.pem)
</cert>
<key>
$(cat $USER/$USER-key.pem)
</key>
EOF

echo ">>> Your client config is available at $USER/$USER.ovpn <<<"

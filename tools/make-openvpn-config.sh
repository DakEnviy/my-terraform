#!/usr/bin/env bash

set -eo pipefail

VPN_DOMAIN='vpn.dakenviy.tech'

if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    >&2 echo "Usage: $0 <certificate_id> <ca_bucket> <vpn_ta_key_secret_id>"
    exit 1
fi

echo 'Retrieving client certificate...'
cert_name=$(yc certificate-manager certificate get --id "$1" --format json | jq -r '.name')
cert_content=$(yc certificate-manager certificate content --id "$1" --format json)
client_cert=$(echo "$cert_content" | jq -r '.certificate_chain[0]')
private_key=$(echo "$cert_content" | jq -r '.private_key')

echo 'Retrieving CA certificate...'
ca_cert=$(curl -s "https://storage.yandexcloud.net/$2/ca.crt")

echo 'Retrieving ta.key...'
ta_key=$(yc lockbox payload get --id "$3" --format json | jq -r '.entries[] | select(.key == "ta_key").text_value')

cat >> "./$cert_name.ovpn" <<EOT
##############################################
# Sample client-side OpenVPN 2.0 config file #
# for connecting to multi-client server.     #
#                                            #
# This configuration can be used by multiple #
# clients, however each client should have   #
# its own cert and key files.                #
#                                            #
# On Windows, you might want to rename this  #
# file so it has a .ovpn extension           #
##############################################

# Specify that we are a client and that we
# will be pulling certain config file directives
# from the server.
client

# Use the same setting as you are using on
# the server.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
;dev tap
dev tun

# Windows needs the TAP-Win32 adapter name
# from the Network Connections panel
# if you have more than one.  On XP SP2,
# you may need to disable the firewall
# for the TAP adapter.
;dev-node MyTap

# Are we connecting to a TCP or
# UDP server?  Use the same setting as
# on the server.
;proto tcp
proto udp

# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote $VPN_DOMAIN 1194
;remote my-server-2 1194

# Choose a random host from the remote
# list for load-balancing.  Otherwise
# try hosts in the order specified.
;remote-random

# Keep trying indefinitely to resolve the
# host name of the OpenVPN server.  Very useful
# on machines which are not permanently connected
# to the internet such as laptops.
resolv-retry infinite

# Most clients don't need to bind to
# a specific local port number.
nobind

# Downgrade privileges after initialization (non-Windows only)
user nobody
group nogroup

# Try to preserve some state across restarts.
persist-key
persist-tun

# If you are connecting through an
# HTTP proxy to reach the actual OpenVPN
# server, put the proxy server/IP and
# port number here.  See the man page
# if your proxy server requires
# authentication.
;http-proxy-retry # retry on connection failures
;http-proxy [proxy server] [proxy port #]

# Wireless networks often produce a lot
# of duplicate packets.  Set this flag
# to silence duplicate packet warnings.
;mute-replay-warnings

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair
# for each client.  A single ca
# file can be used for all clients.
;ca ca.crt
;cert client.crt
;key client.key

# Verify server certificate by checking that the
# certificate has the correct key usage set.
# This is an important precaution to protect against
# a potential attack discussed here:
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the keyUsage set to
#   digitalSignature, keyEncipherment
# and the extendedKeyUsage to
#   serverAuth
# EasyRSA can do this for you.
remote-cert-tls server

# If a tls-auth key is used on the server
# then every client must also have the key.
;tls-auth ta.key 1

# Select a cryptographic cipher.
# If the cipher option is used on the server
# then you must also specify it here.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the data-ciphers option in the manpage
cipher AES-256-GCM
auth SHA256

# Enable compression on the VPN link.
# Don't enable this unless it is also
# enabled in the server config file.
#comp-lzo

# Set log file verbosity.
verb 3

# Silence repeating messages
;mute 20

key-direction 1

<cert>
$client_cert
</cert>

<key>
$private_key
</key>

<ca>
$ca_cert
</ca>

<tls-crypt>
$ta_key
</tls-crypt>
EOT

echo "OpenVPN config was saved to './$cert_name.ovpn' file."

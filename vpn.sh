:
#
# usage: $0 country
#
if [ -z "$1" ] ; then
    echo Usage: $0 country-you-want-to-be-teleported-to [DEBUG]
    echo
    echo "  or, to list what's countries are currently out there -"
    echo
    echo Usage: $0 list
    echo
    exit 1
fi
country="$1"

#
# to see OpenVPN output
#
DEBUG=""
if [ ! -z "$2" -a "$2" == "DEBUG" ] ; then
    DEBUG="YES"
fi

# need openvpn somewhere....
which openvpn &> /dev/null
if [ $? != 0 ]; then
    echo \"openvpn\" must be installed and in your path
    exit 2
fi

#
# shangri-la... but http?  Really? :)
#
URL="http://www.vpngate.net/api/iphone/"

#
# we'll be stuffing the conf in a temp file
#
tmp_conf=$(mktemp)
up_script=$(mktemp)
vpn_output=$(mktemp)

# nuke tmps when done
# trap "rm -f $tmp_conf $up_script $vpn_output" EXIT
# trap "rm -f $tmp_conf $up_script $vpn_output" EXIT


# this is where the list of openvpn servers lives
VPN_SERVERS="$HOME/.vpnlist"

EXPIRE="3000"  # server cache list will expire after 1 hour
CURRENT_TIME=$(date +%s)
STALE_WHEN=$(echo $(expr $CURRENT_TIME - $EXPIRE))

# assume hard -n- crusty
STALE="YES"

# if it's zero length, nuke it
if [ ! -s "$VPN_SERVERS" ] ; then
    rm -f "$VPN_SERVERS"
fi

# check cache file... does it exist, and, if it does, how fresh?
if [ -f "$VPN_SERVERS" ] ; then
    echo cache found, checking age...
    AGE=$(/usr/bin/stat -f %m "$VPN_SERVERS")

    if [ $STALE_WHEN -gt $AGE ] ; then
        STALE="YES"
        echo cache is old, old, old....
    else
        STALE="NO"
        echo cache is still minty fresh
    fi            
fi

if [ "$STALE" = "YES" ]; then
    echo 'getting fresh server list'
    curl -s "$URL" > "$VPN_SERVERS"
fi

if [ $? != 0 ]; then
    echo Failed getting VPN server list from $URL, bailin\'...
    exit 3
fi

#
# special case
#
if [ "$country" == "list" ]; then
    awk -F, 'NR > 2 {print $7, $6}' "$VPN_SERVERS" | sort -u
    exit 0
fi

echo "looking for country $country in server list"

# field 7 is country, last field is config

#HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64
# awk -F, '"'"$country"'" == $7 {print $NF; exit 0}' "$VPN_SERVERS" | /usr/bin/base64 -D > "$tmp_conf"

# choose a somewhat random one of the choices, if any
awk -F, 'BEGIN { n=0 } "'"$country"'" == $7 {vpns[n] = $NF; n++} END { srand(); if (vpns[0]) { print vpns[int(n*rand())] ; exit 0; } }' "$VPN_SERVERS" | /usr/bin/base64 -D > "$tmp_conf"


if [ ! -s "$tmp_conf" ]; then
    echo "Couldn't find country $country"
    exit 4
fi

# a script that will run after connecting to try to figure out what IP & country you're now in
echo "#!/bin/bash

# no longer works....
ip=\$(curl -m 10 -s https://ifconfig.co)
ip=\$(curl -m 10 -s ifconfig.me)

if [ -z "\$ip" ] ; then
    echo
    echo
    echo Cannot determine my IP Address... curl/whois may be blocked, the VPN may not have worked, or....?
    echo
    echo Try going to 'https://www.google.com/search?client=firefox-b-1-d&q=what+is+my+ip' and see what happens?
    echo
    echo
    exit 0
fi

echo 
echo 
echo 
echo my current ip: \$ip
echo
echo trying to get my current location...
echo
echo Grats,you are now in... \$(echo \$(dig +short \$(echo \$ip | awk -F\\. '{printf(\"%s.%s.%s.%s\", \$4,\$3,\$2,\$1)}').origin.asn.cymru.com TXT) | awk -F\\| '{print \$3}')
echo 
echo 
echo 
" > "$up_script"


# Country ... $(dig +short $(echo $ip | awk -F. '{print "$4.$3.$2.$1"}').origin.asn.cymru.com TXT) | awk -F| '{print $3}'

chmod 700 "$up_script"

echo Starting up VPN, you should be magically transported to $country if this all works....

sudo chown root "$up_script"

echo

#
# openvpn doesn't want to play ball... so hack time to run a script when we're really connected
#
sudo openvpn --script-security 2 --config "$tmp_conf" 2>&1 | 
    awk '{ if ("'"$DEBUG"'" != "") print "OpenVPN:", $0} 
        /Initialization Sequence Completed/ { system ("sudo bash '"$up_script"' &"); exit(0)} \
        END { exit(1) }'

if [ ${PIPESTATUS[1]} -ne 0 ]; then
    echo -e "\nVPN stopped...!  (To see VPN output, add 'DEBUG' to the command line invocation, e.g." $0 $* " DEBUG)"
fi


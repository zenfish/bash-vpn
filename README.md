Bash Script to teleport to other countries (well, via OpenVPN)
-----

(Probably Mac/Linux only, unles you have bash, openvpn, and some
prayers installed....)

I ran across [autovpn](https://github.com/adtac/autovpn), which I
thought a nifty idea, but after it died silently I thought I'd just
rewrite it as a shell script... because... if there's anything that
Go shouldn't be used for it's to execute shell commands... IMHO,
at least :)

That said, Autovpn probably works better and people seem to like
it, so by all means use that over this. Mine is untested, mostly
done for fun, so... don't trust your life with it or anything.
There's probably a better script elsewhere else, but...  scriptum,
ergo sum.

Usage:

    vpn.sh country-code

Country codes are two digit codes, like "US", "JP", and the like.

If you want to see the output of OpenVPN doing its job, tack on
"DEBUG" after the country-code, like:

    vpn.sh US DEBUG

Finally, a special "list" argument may be used to get a list of all
the countries currently running VPNs - e.g.

    vpn.sh list

The program stashes a cached copy of the VPN db in your home directory -
in $HOME/.vpnlist. This is done to try and prevent hammering the VPN Gate
project server. It'll fetch a new copy if that file doesn't exist or
if it's over an hour old.


Details
-----

The script -

- fetches a list of servers and VPN configuration files from the awesome [VPN Gate](https://www.vpngate.net/api/iphone/) project 

- tries to match the specified country code from the list, bailing if it can't

- fires up OpenVPN with the appropriate configuration gotten from VPN Gate

- if the connection appears to have worked, tries to tell you what your new IP and country are.


Hopefully Control-C will kill off the script. If things are wonky, you can try to
spot the openvpn process and kill it off, like (in the terminal) -

    $ ps axuww|grep openv
    zen              54194   0.0  0.0  4268792    860 s006  S+    4:15PM   0:00.00 grep -d skip openv
    root             54082   0.0  0.0  4310768   3160 s004  S+    4:15PM   0:00.01 openvpn --script-security 2 --config /var/folders/1w/8x8dq8z96h5821syhxgz6hkm0000gn/T/tmp.DEPdm2Uj
    root             54080   0.0  0.0  4316560   5284 s004  S+    4:15PM   0:00.03 sudo openvpn --script-security 2 --config /var/folders/1w/8x8dq8z96h5821syhxgz6hkm0000gn/T/tmp.DEPdm2Uj
    $ sudo killall openvpn

Good luck, you'll probably need it.


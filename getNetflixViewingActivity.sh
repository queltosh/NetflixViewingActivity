#!/bin/bash

user="$1"
pass="$2"

if [ -z "$user" ] || [ -z "$pass" ];then
  echo "Usage: $0 NetflixUser NetflixPassword"
  exit 1
fi

workdir="$(mktemp -d)"
pushd $workdir &>/dev/null
trap "rm -rf $workdir" 0


cat > curlcommands <<EOF
-A "Mozilla/5.0 (X11; Linux i686 (x86_64)) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.104 Safari/537.36"
-H "Accept-Language: es,en-GB;q=0.8,en;q=0.6"
-H "Accept-Encoding: gzip,deflate"
-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
-H "Connection: keep-alive"
-c netflixcookie
-b netflixcookie
-s
-S

EOF



curl -K curlcommands -o netflixlogin.gz "https://www.netflix.com/es/Login"
(gunzip netflixlogin.gz || mv netflixlogin.gz netflixlogin) 2>/dev/null
auth="$(cat netflixlogin |grep -o 'name="authURL" value="[^"]\+"' |head -n1|sed 's/name="authURL" value="\([^"]\+\)"/\1/g')"

curl -K curlcommands -o netflixlogged.gz   "https://www.netflix.com/Login" --referer "https://www.netflix.com/es/login" --data-urlencode  "email=$user" --data-urlencode "password=$pass" --data-urlencode "rememberMe=true" --data-urlencode "flow=websiteSignUp" --data-urlencode "mode=login" --data-urlencode "action=loginAction" --data-urlencode "withFields=email,password,rememberMe,nextPage" --data-urlencode "authURL=${auth}" --data-urlencode "nextPage="


(gunzip  netflixlogged.gz || mv netflixlogged.gz netflixlogged ) 2> /dev/null
curl -o netflixactivity.gz -K curlcommands "https://www.netflix.com/WiViewingActivity"
(gunzip  netflixactivity.gz || mv netflixactivity.gz netflixactivity ) 2> /dev/null
grep -o '<a href="[^"]\+" data-reactid="[0-9]\+">\([^<]\+\)</a>' netflixactivity |sed 's%<a href="[^"]\+" data-reactid=".*">\([^<]\+\)</a>%\1\n%g'


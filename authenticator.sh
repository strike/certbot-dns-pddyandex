#!/bin/bash

_dir="$(dirname "$0")"

source "$_dir/config.sh"

# Strip only the top domain to get the zone id
DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
	
# Create TXT record
CREATE_DOMAIN="_acme-challenge"
RECORD_ID=$(curl -s -X POST "https://pddimp.yandex.ru/api2/admin/dns/add" \
     -H "PddToken: $API_KEY" \
     -d "domain=$CERTBOT_DOMAIN&type=TXT&content=$CERTBOT_VALIDATION&ttl=3600&subdomain=$CREATE_DOMAIN" \
	 | python -c "import sys,json;print(json.load(sys.stdin)['record']['record_id'])")
	
# Save info for cleanup
if [ ! -d /tmp/CERTBOT_$CERTBOT_DOMAIN ];then
        mkdir -m 0700 /tmp/CERTBOT_$CERTBOT_DOMAIN
fi

echo $RECORD_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID

# Wail to make sure the change has time to propagate over to DNS
c_max=10
for DNS in dns2.yandex.net 8.8.8.8 ; do 
	c=0
	while [ $c -ne $c_max ]; do
		dig $CREATE_DOMAIN.$CERTBOT_DOMAIN -t txt @dns2.yandex.net +short | grep $CERTBOT_VALIDATION && \
			c=$(( $c + 1 )) && sleep 1 && continue \
			|| sleep 60 && c=0
	done
done




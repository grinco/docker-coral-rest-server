docker pull grinco/coral-rest-server
docker stop coral-api
docker rm coral-api
docker run -d --device /dev/apex_0:/dev/apex_0 \
	-p 5000:5000 --restart=unless-stopped \
	--name coral-api grinco/coral-rest-server

#!/bin/bash

username=$1
workername=$2
password=$3

stratum_farm_uri=us-east.equihash-hub.miningpoolhub.com:12023

# run the miner in a pool
# from https://miningpoolhub.com/?page=gettingstarted

while true
do
	# -U: use CUDA
	# -G: use OpenGL
	# -S: stratum server:port
	# -O: stratum credentials
	# -FS: failover
	ethminer --farm-retries 0 \
		-G \
		-S "$stratum_farm_uri" \
		-O "$username.$workername:$password" \
		-FS exit

	break
	ccminer -r 0 -a groestl -o stratum+tcp://hub.miningpoolhub.com:12004 -u $username.$workername -p "$password"
	ccminer -r 0 -a myr-gr -o stratum+tcp://hub.miningpoolhub.com:12005 -u $username.$workername -p "$password"
	ccminer -r 0 -a x11 -o stratum+tcp://hub.miningpoolhub.com:12007 -u $username.$workername -p "$password"
	ccminer -r 0 -a x13 -o stratum+tcp://hub.miningpoolhub.com:12008 -u $username.$workername -p "$password"
	ccminer -r 0 -a x15 -o stratum+tcp://hub.miningpoolhub.com:12009 -u $username.$workername -p "$password"
	ccminer -r 0 -a neoscrypt -o stratum+tcp://hub.miningpoolhub.com:12012 -u $username.$workername -p "$password"
	ccminer -r 0 -a qubit -o stratum+tcp://hub.miningpoolhub.com:12014 -u $username.$workername -p "$password"
	ccminer -r 0 -a quark -o stratum+tcp://hub.miningpoolhub.com:12015 -u $username.$workername -p "$password"
	ccminer -r 0 -a skein -o stratum+tcp://hub.miningpoolhub.com:12016 -u $username.$workername -p "$password"
	ccminer -r 0 -a lyra2v2 -o stratum+tcp://hub.miningpoolhub.com:12018 -u $username.$workername -p "$password"
	ccminer -r 0 -a vanilla -o stratum+tcp://hub.miningpoolhub.com:12019 -u $username.$workername -p "$password"

	echo Done with an interation, sleeping
	sleep 10
done

#!/bin/bash

wallet=$1
worker=$2

ccminer -a cryptonight -o stratum+tcp://xmr-us.mixpools.org:8080 -u $wallet.$worker -p x

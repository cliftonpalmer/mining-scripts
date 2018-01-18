#!/bin/bash

wallet=$1

ccminer -a neoscrypt -o stratum+tcp://us1.gobyte.network:4233 -u $wallet

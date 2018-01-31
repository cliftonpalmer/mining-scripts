#!/bin/bash

wallet=$1

ccminer -a lyra2z -o stratum+tcp://pool.datapaw.net:4553 -u $wallet -p c=XZC,`hostname`

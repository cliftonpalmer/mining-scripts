#!/bin/bash
# some helpful stuff to set up nvidia overclocking for mining
# written by cjp

# init xorg.conf with the installed cards
# must be run with each new card installation?
# nvidia-xconfig --allow-empty-initial-configuration --enable-all-gpus --cool-bits=28 --separate-x-screens

export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

# start X display
X :0 &
sleep 5
export DISPLAY=:0
sleep 3

# settings for each card by type
nvidia-smi -L | sed 's/ (UUID.*$//' | while read line
do
	gpu_id=`echo $line | awk -F': ' '{print $1}' | sed 's/GPU //'`
	gpu_type=`echo $line | awk -F': ' '{print $2}'`

	echo gpu_id: $gpu_id
	echo gpu_type: $gpu_type
	
	if [[ $gpu_type == 'GeForce GTX 1080 Ti' ]]
	then
		# 1080 ti
		nvidia-smi -i $gpu_id -pl 175
		nvidia-settings \
		    -a "[gpu:$gpu_id]/GPUFanControlState=1" \
		    -a "[fan:$gpu_id]/GPUTargetFanSpeed=65" \
		    -a "[gpu:$gpu_id]/GPUGraphicsClockOffset[3]=108" \
		    -a "[gpu:$gpu_id]/GPUMemoryTransferRateOffset[3]=-250"
	elif [[ $gpu_type == 'GeForce GTX 1070' ]]
	then
		# 1070
		nvidia-smi -i $gpu_id -pl 130
		nvidia-settings \
		    -a "[gpu:$gpu_id]/GPUFanControlState=1" \
		    -a "[fan:$gpu_id]/GPUTargetFanSpeed=65" \
		    -a "[gpu:$gpu_id]/GPUGraphicsClockOffset[3]=100" \
		    -a "[gpu:$gpu_id]/GPUMemoryTransferRateOffset[3]=-250"
	else
		echo "Unrecognized GPU: $line"
	fi
done

wait

#!/bin/bash

# must re-initialize the xorg.conf every time a new card is added
nvidia-xconfig \
    --allow-empty-initial-configuration \
    --enable-all-gpus \
    --cool-bits=28 \
    --separate-x-screens

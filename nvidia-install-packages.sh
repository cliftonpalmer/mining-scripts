#!/bin/bash

# installing basic packages for nvidia cards
pacman -Sy \
  cronie \
  cuda \
  nvidia \
  nvidia-settings \
  xorg-server

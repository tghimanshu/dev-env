#!/bin/bash

# Install dependencies
yay -S --noconfirm --needed uxplay
yay -S --noconfirm --needed gst-plugins-good gst-plugins-bad gst-libav

# Allow mDNS (Bonjour) for Apple device discovery
sudo ufw allow 5353/udp

# Allow AirPlay video, audio, and control ports
sudo ufw allow 7000,7001,7100/tcp

# Allow AirPlay RAOP (audio streaming) ports
sudo ufw allow 6000,6001,7011/udp

# Reload UFW to apply the new rules
sudo ufw reload

# ----- REVERSE -----
#
# # Block mDNS (Bonjour) again
# sudo ufw delete allow 5353/udp
#
# # Block AirPlay video, audio, and control ports
# sudo ufw delete allow 7000,7001,7100/tcp
#
# # Block AirPlay RAOP (audio streaming) ports
# sudo ufw delete allow 6000,6001,7011/udp
#
# # Reload UFW to apply the restrictions
# sudo ufw reload
#
#
#
# RUN
# uxplay -p

#!/bin/bash

yay -S --needed --noconfirm flutter

# Linux Drivers
yay -S --needed --noconfirm mesa-utils

yay -S --needed --noconfirm android-studio

sudo groupadd flutterusers
sudo gpasswd -a $USER flutterusers
sudo chown -R :flutterusers /usr/lib/flutter
sudo chmod -R g+w /usr/lib/flutter

yes | sudo /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses

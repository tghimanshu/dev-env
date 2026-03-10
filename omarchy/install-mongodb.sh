#!/bin/bash

yay -S --noconfirm mongodb-bin
sudo systemctl start mongodb
sudo systemctl enable mongodb

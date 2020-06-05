#!/bin/bash

rsync -r /workspaces/SmartBax pi@192.168.0.25:/home/pi
#rsync /workspaces/SmartBax/Package.swift pi@192.168.0.25:/home/pi/SmartBax/Package.swift
#echo "$(ssh pi@192.168.0.25 'cd /home/pi/SmartBax; swift build; swift run')"

#rsync -r pi@192.168.0.25:/home/pi/SmartBax /workspaces
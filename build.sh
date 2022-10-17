#!/bin/sh
swift bundler bundle -c release -o .
plutil -insert MetalCaptureEnabled -bool YES DeltaClient.app/Contents/Info.plist

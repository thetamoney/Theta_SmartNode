#!/bin/bash

COIN_NAME='theta'
COIN_DAEMON='thetad'
COIN_CLI='theta-cli'
COIN_TX='theta-tx'
COIN_PATH='/usr/local/bin'
WALLET_TAR=$(curl -s https://github.com/thetaspere/theta/releases/download/1.3.17.01/Thetacore-ubuntu18-1.3.17.01.tar.gz)

# fetch latest release using github api
if pgrep $COIN_DAEMON; then
  $COIN_CLI stop
  mkdir temp
  curl -L $WALLET_TAR | tar xz -C ./temp; mv ./temp/$COIN_DAEMON ./temp/$COIN_CLI ./temp/$COIN_TX $COIN_PATH
  $COIN_DAEMON
else
  mkdir temp
  curl -L $WALLET_TAR | tar xz -C ./temp; mv ./temp/$COIN_DAEMON ./temp/$COIN_CLI ./temp/$COIN_TX $COIN_PATH
  rm -rf temp
fi
 

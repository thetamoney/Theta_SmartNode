#!/bin/bash

EXECUTABLE='thetad'
DIR='/theta/.thetacore'
CONF_FILE='raptoreum.conf'
FILE=$DIR/$CONF_FILE


# Create directory and config file if it does not exist yet
if [ ! -e "$FILE" ]; then
  mkdir -p $DIR
  if [ -n "$BLS_KEY" ]; then
    cat << EOF > $FILE
rpcuser=$(pwgen -1 8 -n)
rpcpassword=$(pwgen -1 20 -n)
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
index=1
txindex=1
addressindex=1
server=1
listen=1
par=2
dbcache=1024
smartnodeblsprivkey=${BLS_KEY}
externalip=${EXTERNALIP}
addnode=chain.thetaspere.com
addnode=91.90.11.205
addnode=78.186.117.161
addnode=84.42.20.117
addnode=37.192.138.15
addnode=5.2.212.100
addnode=81.133.36.219
addnode=31.173.170.169
addnode=185.31.32.208
EOF
  else
    cat << EOF > $FILE
rpcuser=$(pwgen -1 8 -n)
rpcpassword=$(pwgen -1 20 -n)
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
server=1
listen=1
addnode=chain.thetaspere.com
addnode=91.90.11.205
addnode=78.186.117.161
addnode=84.42.20.117
addnode=37.192.138.15
addnode=5.2.212.100
addnode=81.133.36.219
addnode=31.173.170.169
addnode=185.31.32.208
EOF
  fi
fi

# Create script for HEALTHCHECK
if [ ! -e /usr/local/bin/healthcheck.sh ]; then
  touch healthcheck.sh
  cat << EOF > healthcheck.sh
#!/bin/bash

POSE_SCORE=\$(curl -s "https://chain.thetaspere.com/api/protx?command=info&protxhash=${PROTX_HASH}" | jq -r '.state.PoSePenalty')
if ((POSE_SCORE>0)); then
  kill -15 -1
  sleep 15
  kill -9 -1
else
  echo "Smartnode seems to be healthy..."
fi
EOF
  chmod 755 healthcheck.sh
  mv healthcheck.sh /usr/local/bin
fi

exec $EXECUTABLE -datadir=$DIR -conf=$FILE

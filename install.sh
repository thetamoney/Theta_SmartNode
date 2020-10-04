#!/bin/bash

COIN_NAME='raptoreum'

#wallet information
WALLET_TAR='https://github.com/Raptor3um/Raptoreum/releases/download/2.0b/raptoreum-2.0b-x86_64-linux-gnu.tar'
#BOOTSTRAP_ZIP=''
#BOOTSTRAP_ZIPFILE=''
CONFIG_DIR='.raptoreumcore'
CONFIG_FILE='raptoreum.conf'
PORT='19889'
SSHPORT='22'
COIN_DAEMON='raptoreumd'
COIN_CLI='raptoreum-cli'
COIN_PATH='/usr/local/bin'
USERNAME="$(whoami)"

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
STOP='\e[0m'

#emoji code
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"

#end of required details
#

echo -e "${YELLOW}==========================================================="
echo -e 'RTM Smartnode Setup'
echo -e "===========================================================${NC}"
echo -e "${BLUE}Oct 2020, by AltTank Army and dk808${NC}"
echo -e
echo -e "${CYAN}Node setup starting, press [CTRL-C] to cancel.${NC}"
sleep 5
if [ "$USERNAME" = "root" ]; then
    echo -e "${CYAN}You are currently logged in as ${NC}root${CYAN}, please switch to the username you just created.${NC}"
    exit
fi

#functions
function wipe_clean() {
    echo -e "${YELLOW}Removing any instances of RTM...${NC}"
    sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
    sudo $COIN_CLI stop > /dev/null 2>&1 && sleep 2
    sudo killall $COIN_DAEMON > /dev/null 2>&1
    sudo rm /usr/local/bin/raptoreum* > /dev/null 2>&1 && sleep 1
    sudo rm /usr/bin/raptoreum* > /dev/null 2>&1 && sleep 1
    rm -rf $BOOTSTRAP_ZIP_FILE
    rm -rf sentinel
}

function ssh_port() {
    echo -e "${YELLOW}Detecting SSH port being used...${NC}" && sleep 1
    SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
    if ! whiptail --yesno "Detected you are using $SSHPORT for SSH is this correct?" 8 56; then
        SSHPORT=$(whiptail --inputbox "Please enter port you are using for SSH" 8 43 3>&1 1>&2 2>&3)
        echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    else
        echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
    fi
}

function ip_confirm() {
    echo -e "${YELLOW}Detecting IP address being used...${NC}" && sleep 1
    WANIP=$(wget http://ipecho.net/plain -O - -q)
    if ! whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60; then
        WANIP=$(whiptail --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
    fi
}

function create_swap() {
    echo -e "${YELLOW}Creating swap if none detected...${NC}" && sleep 1
    if ! grep -q "swapfile" /etc/fstab; then
        if whiptail --yesno "No swapfile detected would you like to create one?" 8 54; then
          sudo fallocate -l 4G /swapfile
          sudo chmod 600 /swapfile
          sudo mkswap /swapfile
          sudo swapon /swapfile
          echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
          echo -e "${YELLOW}Created ${SEA}4G${YELLOW} swapfile${NC}"
        fi
    fi
    sleep 2
}

function install_packages() { 
    echo -e "${YELLOW}Installing Packages...${NC}"
    sudo apt-get install software-properties-common -y
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install nano htop pwgen ufw figlet pv -y
    sudo apt-get install build-essential libtool autotools-dev pkg-config libssl-dev libevent-dev -y
    sudo apt-get install libc6-dev m4 g++-multilib -y
    sudo apt-get install python-virtualenv virtualenv -y
    sudo apt-get install libboost-all-dev autoconf ncurses-dev unzip git python python-zmq -y
    sudo apt-get install wget curl bsdmainutils automake fail2ban -y
    sudo add-apt-repository ppa:bitcoin/bitcoin -y
    sudo apt-get update
    sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
    sudo apt-get install libminiupnpc-dev libzmq3-dev -y
    echo -e "${YELLOW}Packages complete...${NC}"
}

function spinning_timer() {
    animation=( ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ )
    end=$((SECONDS+NUM))
    while [ $SECONDS -lt $end ];
    do
        for i in "${animation[@]}";
        do
            echo -ne "${RED}\r$i ${CYAN}${MSG1}${NC}"
            sleep 0.1
        done
    done
    echo -e "${MSG2}"
}

function create_conf() {
    if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
        echo -e "${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
        mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
    fi
    RPCUSER=`pwgen -1 8 -n`
    PASSWORD=`pwgen -1 20 -n`
    smartnodeblsprivkey=$(whiptail --inputbox "Enter your SmartNode BLS Privkey" 8 75 3>&1 1>&2 2>&3)
    echo -e "${YELLOW}Creating Conf File...${NC}"
    sleep 1
    mkdir ~/$CONFIG_DIR > /dev/null 2>&1
    touch ~/$CONFIG_DIR/$CONFIG_FILE
    cat << EOF > ~/$CONFIG_DIR/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
port=$PORT
server=1
daemon=1
listen=1
smartnodeblsprivkey=$smartnodeblsprivkey
externalip=$WANIP
addnode=207.180.236.174
addnode=152.44.40.67
addnode=173.249.7.48
addnode=167.86.76.90
maxconnections=256
EOF
}

function install_bins() {
    echo -e "${YELLOW}Installing binaries...${NC}"
    wget -qO- $WALLET_TAR | tar xv
    sudo mv ~/raptoreum-2.0b-x86_64-linux-gnu/raptoreum* $COIN_PATH
    rm -rf raptoreum-2.0b-x86_64-linux-gnu
}

function bootstrap() {
    if [ -e ~/$CONFIG_DIR/blocks -a -e ~/$CONFIG_DIR/chainstate ]; then
        rm -rf ~/$CONFIG_DIR/blocks ~/$CONFIG_DIR/chainstate
        echo -e "${YELLOW}Downloading wallet bootstrap please be patient...${NC}"
        wget $BOOTSTRAP_ZIP
        unzip $BOOTSTRAP_ZIPFILE -d ~/$CONFIG_DIR
        rm -rf $BOOTSTRAP_ZIPFILE
    else
        echo -e "${YELLOW}Downloading wallet bootstrap please be patient...${NC}"
        wget $BOOTSTRAP_ZIP
        unzip $BOOTSTRAP_ZIPFILE -d ~/$CONFIG_DIR
        rm -rf $BOOTSTRAP_ZIPFILE
    fi
}

function update_script() {
    wget $UPDATE_SCRIPT
    chmod +x $UPDATE_FILE
}

function install_sentinel() {
    echo -e "${YELLOW}Installing sentinel...${NC}"
    git clone https://github.com/dashpay/sentinel.git && cd sentinel
    virtualenv venv
    venv/bin/pip install -r requirements.txt
    #sentinel conf
    SENTINEL_CONF=$(cat <<EOF
raptoreum_conf=/home/$USERNAME/$CONFIG_DIR/$CONFIG_FILE
db_name=/home/$USERNAME/sentinel/database/sentinel.db
db_driver=sqlite
network=mainnet
EOF
)
    echo -e "${YELLOW}Configuring sentinel and cron job...${NC}"
    echo "$SENTINEL_CONF" > ~/sentinel/sentinel.conf
    cd
    crontab -l | grep -v "~/sentinel && ./venv/bin/python bin/sentinel.py" | crontab -
    sleep 1
    crontab -l > tempcron
    echo "* * * * * cd ~/sentinel && ./venv/bin/python bin/sentinel.py > /dev/null 2>&1" >> tempcron
    crontab tempcron
    rm tempcron
}

function create_service() {
    echo -e "${YELLOW}Creating RTM service...${NC}"
    sudo touch /etc/systemd/system/$COIN_NAME.service
    sudo chown $USERNAME:$USERNAME /etc/systemd/system/$COIN_NAME.service
    cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
Type=forking
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/$CONFIG_DIR/
ExecStart=$COIN_PATH/$COIN_DAEMON -datadir=/home/$USERNAME/$CONFIG_DIR/ -conf=/home/$USERNAME/$CONFIG_DIR/$CONFIG_FILE -daemon
ExecStop=-$COIN_PATH/$COIN_CLI stop
Restart=always
RestartSec=3
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
    sudo chown root:root /etc/systemd/system/$COIN_NAME.service
    sudo systemctl daemon-reload
    sleep 4
    sudo systemctl enable $COIN_NAME > /dev/null 2>&1
}

function basic_security() {
    echo -e "${YELLOW}Configuring firewall and enabling fail2ban...${NC}"
    sudo ufw allow $SSHPORT/tcp
    sudo ufw allow $PORT/tcp
    sudo ufw logging on
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw limit OpenSSH
    echo "y" | sudo ufw enable > /dev/null 2>&1
    sudo touch /etc/fail2ban/jail.local
    sudo chown $USERNAME:$USERNAME /etc/fail2ban/jail.local
    cat << EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $SSHPORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
    sudo chown root:root /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
}

function start_daemon() {
    NUM='180'
    MSG1='Starting daemon service & syncing with blockchain please be patient this will take few min...'
    MSG2=''
    if sudo systemctl start $COIN_NAME > /dev/null 2>&1; then
        echo && spinning_timer
        NUM='5'
        MSG1='Getting blockchain info...'
        MSG2="${CHECK_MARK}"
        echo && spinning_timer
        $COIN_CLI getblockchaininfo
    else
        echo -e "${RED}Something is not right the daemon did not start. Will exit out so try and run the script again.${NC}"
        exit
    fi
}

function log_rotate() {
    echo -e "${YELLOW}Configuring logrotate function for debug log...${NC}"
    sleep 1
    if [ -f /etc/logrotate.d/rtmdebuglog ]; then
        echo -e "${YELLOW}Existing log rotate conf found, backing up to ~/rtmdebuglogrotate.old ...${NC}"
        sudo mv /etc/logrotate.d/rtmdebuglog ~/rtmdebuglogrotate.old
        sleep 2
    fi
    sudo touch /etc/logrotate.d/rtmdebuglog
    sudo chown $USERNAME:$USERNAME /etc/logrotate.d/rtmdebuglog
    cat << EOF > /etc/logrotate.d/rtmdebuglog
/home/$USERNAME/.raptoreumcore/debug.log {
  compress
  copytruncate
  missingok
  daily
  rotate 7
}
EOF
    sudo chown root:root /etc/logrotate.d/rtmdebuglog
}

#
#end of functions

#run functions
  wipe_clean
  ssh_port
  ip_confirm
  create_swap
  install_packages
  create_conf
  install_bins
  #bootstrap
  #install_sentinel
  create_service
  basic_security
  start_daemon
  log_rotate
  
printf "${BLUE}"
figlet -t -k "RTM  SMARTNODES" 
printf "${STOP}"

echo -e "${YELLOW}================================================================================================"
echo -e "${GREEN}PLEASE COMPLETE THE SETUP BY REGISTERING YOUR SMARTNODE${NC}"
echo -e "${CYAN}COURTESY OF DK808 FROM ZEL AND ALTTANK ARMY${NC}"
echo
echo -e "${GREEN}Commands to manage $COIN_NAME${NC}"
echo -e "  TO START- ${CYAN}sudo systemctl start $COIN_NAME${NC}"
echo -e "  TO STOP - ${CYAN}sudo systemctl stop $COIN_NAME${NC}"
echo -e "  STATUS  - ${CYAN}sudo systemctl status $COIN_NAME${NC}"
echo -e "In the event server ${RED}reboots${NC} daemon service will ${GREEN}auto-start Raptoreumd${NC}"
echo -e "${YELLOW}================================================================================================${NC}"
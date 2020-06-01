#!/bin/bash
NAME=ubuntu-multipass-dest01
CPU=1
MEM=1G
DISK=5G

## unset any proxy env vars
unset PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

## install commands here
cat <<'EOF' > multipass-commands.txt
sudo apt-get update -y
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq git wget pv tmux iptables-persistent dos2unix debconf-utils
sudo ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
sudo sed -i 's/^#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
echo -e "\nfunction tmuxdemo() { \n  tmux new-session -s demo \;  split-window -v -p 15 \;  select-pane -t 0 \;  resize-pane -Z \; \n}" >> ~/.bashrc
echo -e "\nPS1=\"$ \"" >> ~/.bashrc
echo -e "setw -g mode-keys vi\nset -g mouse on" >> ~/.tmux.conf
EOF

#sudo ssh-keygen -b 2048 -t rsa -f /tmp/sshkey -q -N ""

## launch multipass
multipass launch ubuntu --name $NAME --cpus $CPU --mem $MEM --disk $DISK
sleep 10
multipass list | egrep "^ubuntu-multipass.*Running.*([0-9]{1,3}[\.]){3}[0-9]{1,3}"
if [ $? -ne 0 ]; then 
   echo "[!] multipass instance failed to create, run command below and try again:"
   echo "    #  multipass delete ubuntu-multipass && multipass purge"
   exit 1
fi

## loop thru commands
OLDIFS=$IFS
IFS=$'\n'
echo "[*] `date` -- RUNNING THRU INSTALLS ..."
for line in $(cat multipass-commands.txt); do
  echo "[*] $line"
  multipass exec $NAME -- bash -c ''"$line"''
done
echo "[*] `date` -- DONE WITH INSTALLS ..."
IFS=$OLDIFS
rm multipass-commands.txt

## copy files prefaced with "multipass" into the multipass instance
multipass copy-files multipass* $NAME:

#!/bin/bash
NAME=ubuntu-multipass-ansible
CPU=2
MEM=2G
DISK=5G

## unset any proxy env vars
unset PROXY HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

## install commands here
cat <<'EOF' > multipass-commands.txt
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common jq git wget pv tmux dos2unix tree
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update -y
sudo apt install -y ansible python-pip
sudo pip install ansible-cmdb
ssh-keygen -b 2048 -t rsa -f /home/ubuntu/.ssh/id_rsa -q -N ""
sudo sed -i 's/^#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo echo -e "\nfunction tmuxdemo() { \n  tmux new-session -s demo \;  split-window -v -p 15 \;  select-pane -t 0 \;  resize-pane -Z \; \n}" >> ~/.bashrc
sudo echo -e "\nPS1=\"$ \"" >> ~/.bashrc
sudo echo -e "setw -g mode-keys vi\nset -g mouse on" >> ~/.tmux.conf
EOF

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

## copy files "multipass" into the multipass instance
cd ansible-files
multipass transfer hosts ubuntu-multipass-ansible:; for dir in $(find . ! -path . -type d); do multipass exec ubuntu-multipass-ansible -- bash -c "mkdir $dir"; for file in $(find $dir/ -maxdepth 1 -type f -exec basename '{}' \;); do echo "[*] Copying file $dir/$file ..."; multipass transfer $dir/$file ubuntu-multipass-ansible:$dir; done; done

#!/bin/bash
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`

reset=`tput sgr0`
bold=`tput bold`

yecho() {
  echo ''
  echo "${yellow}${bold}$1${reset}"
  echo ''
}

pause() {
  echo ''
  echo "${yellow}${bold}$1${reset}"
  read -rp "${yellow}Enter to continue, Control-C to stop: ${reset}" key;
  echo ''
}

processorarch=$(dpkg --print-architecture)
yecho "Processor Architecture: $processorarch"

dpkg --configure -a
pause

echo 'Start snap services'
apt install snap-confine
systemctl enable --now snapd.socket
systemctl start snapd.failure.service
systemctl start snapd.snap-repair.service
pause

echo 'Base libraries'
apt-get -y upgrade snapd
apt  install tmux
apt-get -y install xz-utils
apt -y install git
apt -y install software-properties-common
apt-get -y install wget
apt-get -y install nvm
apt -y install curl
apt-get -y install apt-transport-https 
apt-get -y ca-certificates 
apt-get -y gnupg-agent 
apt-get -y software-properties-common
apt -y install lvm2 -y
apt-get -y install gparted
pause

echo 'update snap'
dpkg --configure -a
apt-get -y upgrade snapd
ln -s /var/lib/snapd/snap /snap
apt-get -y upgrage snap
apt-get -y update
apt -y autoremove
pause

yecho 'Clone the Envoy repository'
mkdir dsv
cd dsv
git clone https://github.com/envoyproxy/envoy.git
cd ..
pause 'Finished Clone the Envoy repository'

yecho 'install Node'
apt-get -y update
apt-get -y install nodejs npm
npm -v
npm install npm@latest -g
nvm ls
npm cache clean -f
npm install -g n
n stable
pause 'Finished install Node'

yecho 'install Yarn'
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt-get -y update && apt-get -y install yarn
pause 'Finished install Yarn'

yecho 'install Docker'
apt-get -y remove docker docker-engine docker.io containerd runc
apt-get -y update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=$processorarch] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce
apt-get -y install docker-ce-cli
apt-get -y install containerd.io
docker --version
pause 'Finished install Docker'

yecho 'install KubeCtl'
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get -y update
apt-get -y install -y kubectl
kubectl --version
pause 'Finished install KubeCtl'

yecho 'install VS Code'
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
add-apt-repository "deb [arch=$processorarch] https://packages.microsoft.com/repos/vscode stable main"
apt -y update
apt -y install code
code --version
pause 'Finished install VS Code'

yecho 'install Sublime'
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
apt-get -y update
apt-get -y install sublime-text
pause 'Finished install Sublime'

yecho 'install dotnet core'
wget -q "https://packages.microsoft.com/config/ubuntu/$releaseid/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get -y update
add-apt-repository -y universe
apt-get -y install dotnet-sdk-2.2
dotnet --version
pause 'Finished install dotnet core'

yecho 'install PowerShell'

apt-get -y install linux-azure
apt-get -y install liblttng-ust0 
apt-get -y install libcurl4 
apt-get -y install libkrb5-3
apt-get -y install zlib1g 

yecho 'Installing ICU'
curl http://ftp.br.debian.org/debian/pool/main/i/icu/  --output-document icu.html
grep -oP  '(?<=href=").*?'$processorarch'.deb' icu.html | while read -r line ; do
 wget http://ftp.br.debian.org/debian/pool/main/i/icu/$line
 dpkg -i $line 
 rm $line 
done
rm icu.html

yecho 'Installing SSL'
wget http://ftp.br.debian.org/debian/pool/main/o/openssl  --output-document isl.html
grep -oP  "(?<=href=.)libssl.*?$processorarch.deb" isl.html | while read -r line ; do
 wget http://ftp.br.debian.org/debian/pool/main/o/openssl/$line
 dpkg -i $line 
 rm $line 
done
rm isl.html

curl https://github.com/PowerShell/PowerShell | grep -oP  "(?<=href=.)[A-Za-z0-0/\.\-].*releases/download/.*?linux-x64.tar.gz" | grep -v 'preview' | head -n 1 | while read -r line ; do
	curl -L -o ./pwsh.tar.gz $line
	mkdir -p /opt/microsoft/powershell
	tar zxf ./pwsh.tar.gz -C /opt/microsoft/powershell
	chmod +x /opt/microsoft/powershell/pwsh
	ln -s /opt/microsoft/powershell/pwsh /usr/bin/pwsh
	rm ./pwsh.tar.gz 
done

pwsh --version
pause 'Finished install PowerShell'

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
gecho() {
  echo "${green}${bold}$1${reset}"
}
recho() {
  echo "${red}${bold}$1${reset}"
}

pause() {
  echo ''
  echo "${yellow}${bold}$1${reset}"
  if [ "$pleasepause" != "no" ]; then
    read -rp "${yellow}Enter to continue, Control-C to stop: ${reset}" key;
  fi
  echo ''
}

if [[ "$EUID" -ne 0 ]]; then 
  recho ''
  recho ''
  recho "Please run as root (use sudo -s, then run $0)"
  recho ''
  exit
fi


if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "-?" ]] || [[ "$1" == "help" ]] || [[ "$1" == "--?" ]] || [[ "$1" == "--?" ]]; then
  gecho ''
  gecho ''
  gecho "$0 [--no-pause]"
  gecho "This script will install: docker, kubectl, dotnet core, vs code, sublime, powershell, node, npm, yarn, grunt, gulp, better-vsts-npm-auth, windows-build-tools, git, then clone the repositories teams-modular-packages and Teamspace-Web"
  gecho "If you use the --no-pause option, this script will not stop between each component installation."
  gecho "Without --no-pause, this script will pause and ask for a key to continue between each component installation."
  gecho ""
  exit 1
fi

cd "$HOME"

isInstalled() {
  dpkg-query -l $1 > null
  if [ $? -eq 0 ]; then
	return 0
  else
    return 1
  fi
}

isThisVersion() {
  pattern="$2.*"
  pkgver=$(dpkg-query -f '${Version}' -W $1)
  expr match "$pkgver" $pattern > null
  if [ $? -eq 0 ]; then
	return 0
  else
    return 1
  fi
}

if [ "$1" == "--no-pause" ]; then
  pleasepause='no'
else
  pleasepause='yes'
fi
yecho "Will I pause? $pleasepause"

processorarch=$(dpkg --print-architecture)
releaseid=$(lsb_release --release --short)
yecho "Processor Architecture: $processorarch"
yecho "Release id            : $releaseid"

dpkg --configure -a
pause

echo 'Base libraries'
apt-get -y upgrade snapd
apt     -y install tmux
apt-get -y install xz-utils
apt     -y install git
apt     -y install software-properties-common
apt-get -y install wget
apt-get -y install nvm
apt     -y install curl
apt-get -y install apt-transport-https 
apt-get -y ca-certificates 
apt-get -y gnupg-agent 
apt-get -y software-properties-common
apt     -y install lvm2 
apt-get -y install gparted
pause 'Finished base libraries, about to update snap'

echo 'update snap'
apt     -y purge snapd
apt     -y install snapd
snap    -y install core
apt     -y autoremove
pause 'Finished update snap, about to install Docker'

yecho 'install Docker'
if ! isInstalled docker-ce; then
  apt-get -y remove docker docker-engine docker.io containerd runc
  apt-get -y update
  curl    -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  apt-key fingerprint 0EBFCD88
  add-apt-repository "deb [arch=$processorarch] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get -y update
  apt-get -y install docker-ce
  apt-get -y install docker-ce-cli
  apt-get -y install containerd.io
else
  gecho 'Docker already installed...'
fi
docker --version
pause 'Finished install Docker, about to install KubeCtl'

yecho 'install KubeCtl'
if ! isInstalled kubectl; then
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  apt-get -y update
  apt-get -y install -y kubectl
else
  gecho 'KubeCtl already installed...'
fi  
kubectl version
pause 'Finished install KubeCtl, about to install VS Code'

yecho 'install VS Code'
if ! isInstalled code; then
  wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
  add-apt-repository "deb [arch=$processorarch] https://packages.microsoft.com/repos/vscode stable main"
  apt -y update
  apt -y install code
else
  gecho 'VS Code already installed...'
fi  
code --version
pause 'Finished install VS Code, about to install Sublime'

yecho 'install Sublime'
if ! isInstalled sublime-text; then
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  apt-get -y update
  apt-get -y install sublime-text
else
  gecho 'Sublime already installed...'
fi  
pause 'Finished install Sublime, about to install dotnet core'

yecho 'install dotnet core'
if ! isInstalled dotnet-sdk-2.2; then
  wget -q "https://packages.microsoft.com/config/ubuntu/$releaseid/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
  dpkg -i packages-microsoft-prod.deb
  apt-get -y update
  add-apt-repository -y universe
  apt-get -y install dotnet-sdk-2.2
else
  gecho 'dotnet core already installed...'
fi  
dotnet --version
pause 'Finished install dotnet core, about to install PowerShell'

yecho 'install PowerShell'
which pwsh
if [[ $? -ne 0 ]]; then
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
else
  gecho 'PowerShell already installed'
fi
pwsh --version
pause 'Finished install PowerShell, about to install Node'

yecho 'install Node'
apt-get -y install nodejs
apt-get -y install npm
npm -v
npm install -g n
n 8.11.4
npm install npm@5.6.0 -g
npm cache clean -f

pause 'Finished install Node, about to install npm modules'



yecho 'install npm modules'
npm install -g yarn@1.5.1
npm install -g better-vsts-npm-auth
npm install -g grunt-cli
npm install -g gulp
npm install -g xpm

#if [[ "$processorarch" == "x64" ]]; then#
#	npm install -g --vs2015 --production windows-build-tools
#else
#	recho ''
#	recho "Could not install windows-build-tools. It needs processor arch x64, but this machine has $processorarch..."
#	recho ''
#fi

pause 'Finished install npm modules, about to clone repositories'

yecho 'Cloning repositories'

gecho ''
gecho 'Attention: in order to clone the repositories, you must have'
gecho 'your Personal Access Token from Azure DevOps.'
gecho 'If git asks for your user name and password, use your alias@microsoft.com'
gecho 'as user name, and the Personal Access Token as password.'
gecho 'You can get the Personal Access Token from '
gecho 'https://domoreexp.visualstudio.com/_usersSettings/tokens'
gecho ''

gecho "Before cd $HOME"
cd "$HOME"
if [[ ! -d "$HOME/teams" ]]; then
  mkdir "$HOME/teams"
fi
gecho "Before cd $HOME/teams"
cd "$HOME/teams"
gecho "$(pwd)"

if [ ! -d "teams-modular-packages" ]; then
  git clone https://domoreexp.visualstudio.com/DefaultCollection/Teamspace/_git/teams-modular-packages
fi
if [ ! -d "Teamspace-Web" ]; then
  git clone https://domoreexp.visualstudio.com/DefaultCollection/Teamspace/_git/Teamspace-Web
fi
pause 'Finished Cloning repositories, about to leave the script...'

cd "$HOME"

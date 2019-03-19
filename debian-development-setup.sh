#!/bin/bash
#
# Setup new Debian to run Docker and Development Tools
##

cat bin/.bash_aliases > ~/.bash_aliases;
sudo cp -f debian/sources.list /etc/apt/sources.list;
cat config/.env > ~/.env;
pushd ~ && source .env;
popd;
mkdir -p ~/workspace/
sudo apt-get -q update;

sudo apt-get -y install libcurl3 gconf2 curl python apt-utils iputils-ping telnet openssh-server \
    apt-transport-https \
    ca-certificates \
    wget gnupg2 \
    git-all git-cola \
    software-properties-common \
    inkscape clang-format-3.8 gimp firefox-esr libappindicator3-1 \
    libindicator3-7 libdbusmenu-glib4 libdbusmenu-gtk3-4;

#Docker
command -v docker >/dev/null 2>&1 || {
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh;
  sudo sh /tmp/get-docker.sh;
  sudo groupadd docker;
  sudo usermod -aG docker $USER;
}
#docker-compose
command -v docker-compose >/dev/null 2>&1 || {
  sudo rm /usr/bin/docker-compose
  sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose;
  sudo chmod +x /usr/local/bin/docker-compose;
  sudo ln -snf /usr/local/bin/docker-compose /usr/bin/docker-compose ;
  docker-compose version;
}

# Httpd Gateway
if [ ! -d ~/httpd-gateway ]; then
  pushd ~ && git clone https://github.com/gpupo/httpd-gateway.git && pushd httpd-gateway && make setup;
  popd;
fi

# SSH Key
if [ ! -f ~/.ssh/id_rsa.pub ]; then
  ssh-keygen -t rsa -b 4096 -C "${USER}@debian";
  cat ~/.ssh/id_rsa.pub;
fi

#ATOM
command -v apm >/dev/null 2>&1 || {
  LatestUrlRedirection="$(curl https://github.com/atom/atom/releases/latest)"
  LatestVersionUrl="$(grep -o -E 'href="([^"#]+)"' <<< $LatestUrlRedirection)"
  PrefixUrlForDownload="$(cut -d'"' -f2 <<< $LatestVersionUrl)"
  PrefixUrlForDownload="$(awk '{gsub(/tag/,"download")}1' <<< $PrefixUrlForDownload)"
  SufixUrlForDownload="/atom-amd64.deb"
  UrlForDownload="$PrefixUrlForDownload$SufixUrlForDownload"
  wget --progress=bar $UrlForDownload -O /tmp/atom-amd64.deb;
  sudo dpkg -i /tmp/atom-amd64.deb && rm /tmp/atom-amd64.deb;
}

#Atom config and packages
if [ ! -d ~/.atom/packages/language-dotenv ]; then
  apm install --packages-file debian/apm-packages
  cat debian/atom-config.cson > ~/.atom/config.cson
fi

#Chrome
command -v chrome-gnome-shell >/dev/null 2>&1 || {
  wget  --progress=bar https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb;
  sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb && rm /tmp/google-chrome-stable_current_amd64.deb;
}

#Locate
command -v locate >/dev/null 2>&1 || {
  sudo apt-get install locate;
  sudo updatedb;
}

#PHP and xtras
command -v php >/dev/null 2>&1 || {
  sudo apt-get install -y apt-utils iputils-ping procps\
    unzip zlib1g-dev libpng-dev libjpeg-dev gettext-base libxml2-dev libzip-dev \
    libmcrypt-dev mysql-client libicu-dev \
    libcurl4-openssl-dev pkg-config libssl-dev telnet vim netcat \
    php-intl php-gd php-apcu php-zip;
}

#Composer
command -v composer >/dev/null 2>&1 || {
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;";
  php composer-setup.php;
  php -r "unlink('composer-setup.php');"
  sudo mkdir -p /usr/local/bin/;
  sudo mv -v composer.phar /usr/local/bin/composer; sudo chmod +x /usr/local/bin/composer;
  composer global require bamarni/symfony-console-autocomplete:dev-master;
}

sudo apt --fix-broken install;

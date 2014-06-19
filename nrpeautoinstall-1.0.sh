#!/bin/sh
#
##################################################################################################
#
# Description : Installation automatique de NRPE sur Ubuntu/Debian
# Syntaxe: # sudo ./nrpeautoinstall-1.0.sh
# NB: Xinetd n'est pas pris en charge dans cette version.
#
##################################################################################################
#
# Copyright (C) 2013 - Jubama.fr
# Contact : postmaster@jubama.fr
#
##################################################################################################
#
# Ce programme est libre, vous pouvez le redistribuer et/ou le modifier selon les termes de
# la Licence Publique Générale GNU publiée par la Free Software Foundation. Ce programme est
# distribué car potentiellement utile, mais SANS AUCUNE GARANTIE, ni explicite ni implicite,
# y compris les garanties de commercialisation ou d'adaptation dans un but spécifique.
#
##################################################################################################

version="1.0"

nagios_plugins_version="1.5"
nrpe_version="2.13"

apt="apt-get -q -y --force-yes"
wget="wget --no-check-certificate -c"
check_x64=`uname -a | grep -e "_64"`

# Fonction: installation
installation() {
  # Pre-requis
  echo "----------------------------------------------------"
  echo "Installation de pre-requis"
  echo "----------------------------------------------------"
  $apt install wget build-essential libperl-dev
  $apt install snmp snmpd  
  $apt install libnet-snmp-perl libgnutls-dev
  $apt install libssl-dev openssl-blacklist openssl-blacklist-extra

  # Creation de l'utilisateur nagios et du groupe nagios
  echo "----------------------------------------------------"
  echo "Creation de l'utilisateur nagios"
  echo "----------------------------------------------------"
  useradd -m -G www-data -s /bin/bash nagios
  echo "Fixer un mot de passe pour l'utilisateur nagios"
  passwd nagios

  # Recuperation des sources
  echo "----------------------------------------------------"
  echo "Telechargement des sources"
  echo "Nagios Plugin version: $nagios_plugins_version"
  echo "NRPE version:          $nrpe_version"
  echo "----------------------------------------------------"
  mkdir /tmp/nrpeinstall
  cd /tmp/nrpeinstall
  $wget https://www.nagios-plugins.org/download/nagios-plugins-$nagios_plugins_version.tar.gz
  $wget http://heanet.dl.sourceforge.net/project/nagios/nrpe-2.x/nrpe-$nrpe_version/nrpe-$nrpe_version.tar.gz

  # Compilation de Nagios plugins
  echo "----------------------------------------------------"
  echo "Compilation de Nagios plugins"
  echo "----------------------------------------------------"
  cd /tmp/nrpeinstall
  tar zxvf nagios-plugins-$nagios_plugins_version.tar.gz
  cd nagios-plugins-$nagios_plugins_version
  ./configure --with-nagios-user=nagios --with-nagios-group=nagios
  make
  make install

  # Compilation de NRPE
  cd /tmp/nrpeinstall
  echo "----------------------------------------------------"
  echo "Compilation de NRPE"
  echo "----------------------------------------------------"
  tar zxvf nrpe-$nrpe_version.tar.gz
  cd nrpe-$nrpe_version
  
  echo "----------------------------------------------------"
  echo "Configuration de NRPE"
  echo "----------------------------------------------------"
  while true
  do
    echo "----------------------------------------------------" 
    echo -n "Souhaitez-vous installer NRPE (A)vec SSL ou (S)ans SSL ?"
    read sslanswer
 
  # NRPE peut etre installe avec ou sans support SSL
    case $sslanswer in
         A|a)
			  if [[ $check_x64 -ne 0 ]]; then
			  	./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu --enable-command-args --enable-ssl
			  else
			  	./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib --enable-command-args --enable-ssl
			  fi
			  make all
              break
              ;;
         S|s)
			  ./configure -disable-ssl 
			  make all
              break
              ;;
          *)
               echo "Mauvaise reponse, reessayez."
     esac
  done
     
  # Compilation et parametrage du lancement au demarrage
  make install-plugin 
  make install-daemon 
  make install-daemon-config
  cp -a init-script.debian /etc/init.d/nrpe
  chmod 755 /etc/init.d/nrpe
  update-rc.d nrpe defaults
  /etc/init.d/nrpe start

  # On supprime les fichiers temporaires
  cd ~
  rm -rf /tmp/nrpeinstall
}

# Fonction: Check de l'installation de NRPE
confignrpe() {
  echo "----------------------------------------------------"
  echo "Configuration de NRPE (suite)"
  echo "----------------------------------------------------"
  
  while true
  do
    echo -n "Quelle est l'IP du serveur Nagios ?"
	read nagiosip
	
	echo -n "IP du serveur Nagios ? : $nagiosip (Y/N)"
	read nagiosanswer
    case $nagiosanswer in
         Y|y)
			  sed -i 's/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,'"$nagiosip"'/g' /usr/local/nagios/etc/nrpe.cfg
			  sed -i 's/dont_blame_nrpe=0/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg
			  echo "Fichier nrpe.cfg modifie avec succes."
              break
              ;;
          *)
     esac
  done
}

# Fonction: Check de l'installation de NRPE
check() {
  echo "----------------------------------------------------"
  echo "Verification du fonctionnement de NRPE"
  echo "----------------------------------------------------"
  echo -n "Ecoute active ? : "
  statusport=`netstat -at | grep 5666`
  statusnrpe=`netstat -at | grep nrpe`
  if [[ $statusport == "" ]]; then
        if [[ $statusnrpe == "" ]]; then
                echo "NRPE n'est pas lance, il y a eu un probleme lors de l'installation."
        else
                echo "NRPE lance sur le port par defaut (TCP/5666)."
				echo -n "Version installee : "
				/usr/local/nagios/libexec/check_nrpe -H localhost
        fi
  else
                echo "NRPE lance sur le port par defaut (TCP/5666)."
                echo "Pensez a definir le service dans /etc/services."
				echo -n "Version installee : "
				/usr/local/nagios/libexec/check_nrpe -H localhost
  fi
}

# Programme principal
if [ "$(id -u)" != "0" ]; then
	echo "Il faut les droits d'administration pour lancer ce script."
	echo "Syntaxe: sudo $0"
	exit 1
fi
installation
confignrpe
check

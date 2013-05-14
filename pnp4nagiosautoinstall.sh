#!/bin/sh
#
##################################################################################################
#
# Description : Installation automatique de PNP4Nagios sur Ubuntu/Debian
# Syntaxe: # sudo ./pnp4nagiosautoinstall.sh
#
##################################################################################################
# Copyright (C) 2013 - Jubama.fr
##################################################################################################
#
# Ce programme est libre, vous pouvez le redistribuer et/ou le modifier selon les termes 
# de la Licence Publique Générale GNU publiée par la Free Software Foundation. Ce programme
# est distribué car potentiellement utile, mais SANS AUCUNE GARANTIE, ni explicite ni 
# implicite, y compris les garanties de commercialisation ou d'adaptation dans un but spécifique 
#
##################################################################################################

version="1.0"

pnp4_nagios_version="0.6.19"

apt="apt-get -q -y --force-yes"
wget="wget --no-check-certificate -c"

# Fonction: installation
installation() {
  # Pre-requis
  echo "----------------------------------------------------"
  echo "Installation des pre-requis..."
  echo "----------------------------------------------------"
  $apt install wget rrdtool librrds-perl php5-gd

  # Recuperation des sources
  echo "----------------------------------------------------"
  echo "Telechargement des sources..."
  echo "PNP4Nagios version: $pnp4_nagios_version"
  echo "----------------------------------------------------"
  mkdir /tmp/pnp4nagiosinstall
  cd /tmp/pnp4nagiosinstall
  $wget http://freefr.dl.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-$pnp4_nagios_version.tar.gz
  
  # Compilation de Nagios plugins
  echo "----------------------------------------------------"
  echo "Compilation de PNP4Nagios..."
  echo "----------------------------------------------------"
  cd /tmp/pnp4nagiosinstall
  tar xvzf pnp4nagios-$pnp4_nagios_version.tar.gz
  cd pnp4nagios-$pnp4_nagios_version
  ./configure

  while true
  do
    echo "----------------------------------------------------" 
    echo -n "La configuration ci-dessus est-elle correcte (O/N) ?"
  echo "----------------------------------------------------" 
    read configanswer
 
    case $configanswer in
         O|o)
			  make all
			  make install
			  make install-webconf
			  make install-config
			  make install-init
			  /etc/init.d/apache2 restart
              break
              ;;
         N|n)
			  echo "Passez a une installation manuelle du produit."
			  echo "Doc. officielle : http://docs.pnp4nagios.org/fr/pnp-0.6/install#installation_et_plus"
			  exit 1
              break
              ;;
          *)
               echo "Mauvaise reponse, reessayez."
     esac
  done
  
  # On supprime les fichiers temporaires
  cd ~
  rm -rf /tmp/pnp4nagiosinstall
}

# Fonction: rappel du restant
afterinstall() {
  echo "----------------------------------------------------"
  echo "- PNP4Nagios est maintenant installe :"
  echo "----------------------------------------------------"
  echo "- Fichiers PHP : /usr/local/pnp4nagios/share/pnp "
  echo "- Process perfdata : /usr/local/pnp4nagios/libexec"
  echo "- Config.php : /usr/local/pnp4nagios/etc"
  echo "- Exemples de config. : /usr/local/pnpnagios/etc"
  echo "----------------------------------------------------"
  echo "- Have Fun ! Jubama.fr - "
  echo "----------------------------------------------------"
  exit 0 
  }

# Programme principal
if [ "$(id -u)" != "0" ]; then
	echo "Il faut les droits d'administration pour lancer ce script."
	echo "Syntaxe: sudo $0"
	exit 1
fi
installation
afterinstall

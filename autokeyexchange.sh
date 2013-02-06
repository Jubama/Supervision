  #!/bin/sh
#
##################################################################################################
#
# Description : Installation automatique de votre cle publique sur un serveur distant
# Syntaxe: # sudo ./autokeyexchange.sh
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

# Fonction: installation
installation() {
    echo "----------------------------------------------------"
    echo "Mise a jour des sources"
    echo "----------------------------------------------------"
  apt-get update
	echo "----------------------------------------------------"
    echo "Installation d'openssh-client"
    echo "----------------------------------------------------"
	apt-get -q -y --force-yes install openssh-client
    echo "----------------------------------------------------"
    echo "Génération des cles"
    echo "----------------------------------------------------"
	ssh-keygen -t dsa -b 1024
}
	
# Fonction: copykey
copykey() {
    echo "----------------------------------------------------"
    echo "Copie de la cle publique sur le serveur distant"
    echo "----------------------------------------------------"
	echo "Le mot de passe du serveur distant vous sera demande"
	echo "----------------------------------------------------"
    
	while true
    do
		echo "Indiquer le login et IP du serveur distant au format login@serveur.distant.fr"
		echo "Pour des raisons evidentes de securite, il est deconseille de mettre 'root' en login !"
		read loginip

		echo -n "Est ce correct ? : $loginip (O/N)"
		read answer
		case $answer in
			O|o)
			  # Copie de la cle publique sur le serveur distant
			  ssh-copy-id -i ~/.ssh/id_dsa.pub $loginip
              break
              ;;
			*)
		esac
	done
}

# Fonction: check
check() {
    echo "-----------------------------------------------------------------"
    echo "Verification de l'installation: connexion sur la machine distante"
    echo "-----------------------------------------------------------------"
	
	while true
    do
		echo -n "Verifier maintenant la connexion sur le serveur distant ? (O/N)"
		read connectanswer

		case $connectanswer in
			O|o)
			  ssh  $loginip
              break
              ;;
			*)
		esac
	done
}

# Programme principal
if [ "$(id -u)" != "0" ]; then
	echo "Il faut les droits d'administration pour lancer ce script."
	echo "Syntaxe: sudo $0"
	exit 1
fi
installation
copykey
check

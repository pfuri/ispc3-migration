#!bin/bash
# Title: ISPConfig Migration - Backup Protocol
# Description: This script is part of a collection of scripts to assist in migrating an existing ISPConfig 3 installation to a new server. Particularly, this script handles the backup of the old server and prepares it for the transfer.
# Author: Unfaiir
# Copyright 2014, Unfaiir Advantage
# Version: 1.0
# License: GPL v3

# Defaults
AUTHOR="Unfaiir";
BDIRS="";
COPYRIGHT="Copyright 2014, Unfaiir Advantage";
DBNAME="mysqld";
DBPASS="";
DBUSER="root";
DESCRIPTION1="This script is part of a collection of scripts to assist in migrating an existing ISPConfig 3 installation to a new server.";
DESCRIPTION2="Particularly, this script handles the backup of the old server and prepares it for the transfer.";
LICENSE="GPL v3";
MDIR="/tmp/ispcm";
MTIME=`date +"%Y%m%d%H%I%S"`;
TITLE="ISPConfig Migration - Backup Protocol";
VERSION="1.0";

# Backup Dirs Config
#       * Ucomment directories you wish to migrate
#       * Comment directories you do not wish to migrate
#       * Add additional directories you wish to migrate that are not listed using the same format
BDIRS="${BDIRS} /etc/Bastille/firewall.d";
#BDIRS="${BDIRS} /etc/bind";
BDIRS="${BDIRS} /etc/cron.d";
#BDIRS="${BDIRS} /etc/dovecot";
BDIRS="${BDIRS} /etc/fail2ban";
BDIRS="${BDIRS} /etc/httpd";
BDIRS="${BDIRS} /etc/my.cnf";
BDIRS="${BDIRS} /etc/named";
BDIRS="${BDIRS} /etc/php.ini";
#BDIRS="${BDIRS} /etc/php5";
#BDIRS="${BDIRS} /etc/phpmyadmin";
BDIRS="${BDIRS} /etc/phpMyAdmin";
BDIRS="${BDIRS} /etc/postfix";
BDIRS="${BDIRS} /etc/squirrelmail";
BDIRS="${BDIRS} /usr/lib/courier-imap";
BDIRS="${BDIRS} /usr/local/ispconfig/interface/lib";
BDIRS="${BDIRS} /usr/local/ispconfig/server/lib";
BDIRS="${BDIRS} /etc/postfix";
BDIRS="${BDIRS} /var/lib/phpMyAdmin";
BDIRS="${BDIRS} /var/lib/squirrelmail";
BDIRS="${BDIRS} /var/log";
BDIRS="${BDIRS} /var/vmail";
BDIRS="${BDIRS} /var/www";



#*************************************
# END CONFIG - DO NOT EDIT PAST HERE *
#*************************************

# get the backup location and make sure it exists and is writable
function getBackupLocation {
        # Prompt user for backup location
        PROMPT="Where should the backup be stored? (Do not use a trailing slash) [/tmp/ispcm]: ";
        read -p "${PROMPT}" MDIR;
        if [ -z "${MDIR}" ]; then
                MDIR="/tmp/ispcm";
        fi;
        # TODO: Remove trailing slashes

        # Verify directory permissions and create if necessary
        if [ ! -d "${MDIR}" ]; then
                # TODO: Verify user has permission to create the location

                PROMPT="The location '${MDIR}' does not exist, do you wish to create it now? [yes]: ";
                read -p "${PROMPT}" RESPONSE;
                if [ -n "${RESPONSE}" ] && [ "${RESPONSE}" != "yes" ]; then
                        MESSAGE="Error: Cannot continue without a backup directory to use\n";
                        printf "${MESSAGE}";
                        exit 1;
                fi;

                # Create the directory
                printf "Creating backup location...\n ";
                mkdir -p "${MDIR}";
                if [ -d "${MDIR}" ]; then
                        MESSAGE="Successfully created backup directory: ${MDIR}\n";
                        printf "${MESSAGE}";
                else
                        MESSAGE="Error: Could not created backup directory: ${MDIR}\n";
                        printf "${MESSAGE}";
                        exit 1;
                fi;
        fi;

        # TODO: Verify location has write permissions
}

function getMySQLVars {
        # Prompt for MySQL service name
        #PROMPT="What is your MySQL service name [default: mysqld]: ";
        #read -p "${PROMPT}" DBNAME;
        #if [ -z "${DBNAME}" ]; then
        #       DBNAME="mysqld";
        #fi;

        # Prompt for MySQL username
        PROMPT="Enter a MySQL user with full backup privileges [root]: ";
        read -p "${PROMPT}" DBUSER;
        if [ -z "${DBUSER}" ]; then
                DBUSER="root";
        fi;

        # Prompt for MySQL user password
        PROMPT="Enter password for ${DBUSER}: ";
        read -sp "$PROMPT" DBPASS;
        printf "\n";

        # Verfy MySQL username, password and privalages
        # TODO: Verify mysql username/password are correct
        # TODO: Verify mysql user has sufficient privalages
}

# Create the list of directories to backup for migration
function setBackupDirs {
        # TODO: Optimize what is backed up by default to the very minimum
        # TODO: Do a search for the ISPConfig 3 possible applications and create the default directories dynamically based on what is currently installed
        # TODO: Let user choose which of the default directories to backup
        # TODO: Let user add additional directories to backup
        MESSAGE="The following directories will be backed up: ${BDIRS}\n";
        printf "${MESSAGE}";

        PROMPT="Does this look correct? [yes]: ";
        read -p "${PROMPT}" RESPONSE;
        if [ -n "${RESPONSE}" ] && [ "${RESPONSE}" != "yes" ]; then
                MESSAGE="Error: User cancelled because backup directories were not correct\n";
                printf "${MESSAGE}";
                exit 1;
        fi;
        printf "${MESSAGE}";
}

function backupMySQL {
        # Backup and compress all MySQL databases
        printf "Backing up all databases...\n";
        DUMPFILE="${MDIR}/mysqldump-all-databases-${MTIME}.sql";
        mysqldump -u "${DBUSER}" -p"${DBPASS}" --all-databases > "${DUMPFILE}" 2>&1;
        if [ "$?" -eq 0 ]; then
                printf "Successfully created ${DUMPFILE}\n";
        else
                printf "Error: Could not create mysqldump\n";
                exit 1;
        fi;

        printf "Compressing mysqldump:\n";
        TARFILE="${MDIR}/mysqldump-all-databases-${MTIME}.tar.gz";
        tar -zcvpf "${TARFILE}" "${DUMPFILE}" 2>&1;
        if [ "$?" -eq 0 ]; then
                printf "Successfully compressed mysqldump: ${TARFILE}\n";
        else
                printf "Error: Could not compress mysqldump: ${DUMPFILE}\n";
                exit 1;
        fi;

        printf "Removing mysqldump file...\n";
        rm -f "${DUMPFILE}";
        if [ "$?" -eq 0 ]; then
                printf "Successfully removed ${DUMPFILE}\n";
        else
                printf "Warning: Could not remove mysqldump: ${DUMPFILE}\n";
                exit 1;
        fi;
}

# Backup and compress the backup directories
function backupDirs {
        printf "Backing up directories...\n";
        TARFILE="${MDIR}/filedump-${MTIME}.tar.gz";
        tar -zcvpf "${TARFILE}" --ignore-failed-read `echo "${BDIRS}"` 2>&1;
        if [ "$?" -eq 0 ]; then
                printf "Backup directories successfully compressed: ${TARFILE}\n";
        else
                printf "Error: Could not compress backup directories: ${BDIRS}\n";
                exit 1;
        fi;
}

function welcome {
        STARS="*************************************";
        MESSAGE="\n\n${STARS}\n${TITLE}\n${STARS}\n\tDESCRIPTION:\n\t\t${DESCRIPTION1}\n\t\t${DESCRIPTION2}\n\tVersion: ${VERSION}\n\tAuthor: ${AUTHOR}\n\t${COPYRIGHT}\n\tLicense: ${LICENSE}\n${STARS}\n\n";
        printf "${MESSAGE}";
}

function backup {
        # welcome
        welcome;

        # init
        getBackupLocation;
        getMySQLVars;
        setBackupDirs;

        # backup
        backupMySQL;
        backupDirs;
}

# Do Backup Process
backup;
exit 0;

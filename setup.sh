#!/bin/bash
#colors
#=======
export black=`tput setaf 0`
export red=`tput setaf 1`
export green=`tput setaf 2`
export yellow=`tput setaf 3`
export blue=`tput setaf 4`
export magenta=`tput setaf 5`
export cyan=`tput setaf 6`
export white=`tput setaf 7`

# reset to default bash text style
export reset=`tput sgr0`

# make actual text bold
export bold=`tput bold`

# make background color on text
export bold_mode=`tput smso`

# remove background color on text
export exit_bold_mode=`tput rmso`

#make files executable
chmod +x reporting/alldata.sh
chmod +x reporting/monthend.sh
chmod +x reporting/send_report.sh
chmod +x reporting/fix_crazy/fixcrazy
chmod +x backupdb/remove_old_backups.sh

#make backups and reports directories if they don't exist
DIRECTORIES=( ~/reports ~/backups )
for DIRECTORY in ${DIRECTORIES[@]}; do
	if [ ! -d "$DIRECTORY" ]; then
		mkdir "$DIRECTORY"
	else
		echo "${blue}$DIRECTORY already exists. Skipping this step${reset}"
	fi
done

#If backup.py script already exists, replace it with latest version. If not, create it
test -f ~/backups/backup.py
if [ "$?" = "0" ]; then
	rm ~/backups/backup.py
	echo "Removing old backup script"
	cp backupdb/backup.py ~/backups
	echo "Inserting latest backup script"
else
	echo "Backup script doesnt exist. Copying now..."
	cp backupdb/backup.py ~/backups
fi

#If bash aliases already exists, replace it with latest version. If not, create it
cd ~
test -f ~/.bash_aliases
if [ "$?" = "0" ]; then
	echo "Bash aliases file already exists. Replacing with latest version"
	sudo rm .bash_aliases
	echo "${blue}Replacing aliases with latest version${reset}"
	sudo cp .scripts/.bash_aliases ~
else
	echo "${blue}${bold}Aliases file does not exist. Inserting latest version${reset}"
	sudo cp ~/.scripts/.bash_aliases ~
fi

#test if upgrade script exists. If not add it
test -f ~/upgrade
if [ "$?" = "0" ]; then
	echo "Upgrade script already exists. Replacing with latest version"
	sudo rm upgrade
	echo "Replacing upgrade script with latest version"
	sudo cp .scripts/upgrade ~
else
	echo "Upgrade script does not exist. Inserting it now"
	sudo cp ~/.scripts/upgrade ~
fi

# Install sqlite3 package if not already installed
if [ $(dpkg-query -W -f='${Status}' sqlite3 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Installing sqlite3 package"
  sudo apt-get install -y sqlite3 > /dev/null
else
  echo "sqlite3 package already installed. Skipping.."
fi

#reduce idle session timeout to 12.5 minutes
~/.scripts/config/reduce_session_timeout > /dev/null

#Make simplifed login work even when over 1000 students present at facility
~/.scripts/config/fix_user_limit_on_simplified_login > /dev/null

# Run backup script
~/.scripts/backupdb/backup.sh > /dev/null

#Send testfile to make sure scripts are correctly set up
touch ~/reports/test.R
echo "Testing report submission..."
sshpass -p $SSHPASS scp ~/reports/test.R edulution@130.211.93.74:/home/edulution/reports

# if connection lost the script will exit with status 1 and output error message
if [ "$?" = "0" ]; then
	echo "Report submitted successfully!"
	echo "Everything has been set up correctly"
else
	echo Something went wrong or internet connection was lost 1>&2
	exit 1
fi

# Delete testfile
rm ~/reports/test.R

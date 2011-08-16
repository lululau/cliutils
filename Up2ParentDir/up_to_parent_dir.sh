#!/bin/bash

######################################################################
#                                                                    #
#  download this script, then rename it to ~/.up_to_parent_dir.sh    #
#  then add a line ". ~/.up_to_parent_dir.sh" to ~/.bashrc or/and    #
#  ~/.bash_profile depending on the type of your shell.              #
#                                                                    #
######################################################################

function up() {
    if [ "$#" -eq 0 ]
    then
	count=2
    elif [ "$#" -eq 1 ] && echo $1 | grep -q '^[0-9]\+$'
    then
	count=$1
    else 
	echo 'up <count>' 2>&1
	return
    fi
    for ((i = 0; i < count; i++)) 
    do
	cd ..
    done
}
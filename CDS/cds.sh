#!/bin/bash

######################################################################
#                                                                    #
#  download this script, then rename it to ~/.cds.sh    #
#  then add a line ". ~/.cds.sh" to ~/.bashrc or/and    #
#  ~/.bash_profile depending on the type of your shell.              #
#                                                                    #
######################################################################

function cds() {
    if [ "$#" -eq 1 ] && echo $1 | grep -q '^-\?[0-9]\+$'
    then
	line=$1
	if echo $1 | grep -q '^-[0-9]\+$'
	then
	    lines_total=$(ls | wc -l | grep -o '[0-9]\+')	    
	    line=$((lines_total + 1 + line))
	fi
	cd "$(ls | sed -n ${line}p)"
    else
	echo "cds <count>" >&2
    fi
}
#!/bin/bash


##########################################################################
#
# i -f my_text_file -b .bak iconv -f UTF-8 my_text_file
# i -f my_text_file  iconv -f UTF-8 my_text_file
# i iconv -f UTF-8 my_text_file
# 
# cat my_text_file | rev | cut -d' ' -f 2 | i -f my_text_file -b .bak
# cat my_text_file | rev | cut -d' ' -f 2 | i -f my_text_file
#
#########################################################################

COMMAND_NAME=$(basename $0)

function print_usage() {
    cat <<EOF >&2
USAGE: ${COMMAND_NAME}
EOF
}

function log_err() {
    echo "错误: $1" >&2
}

FILE_NAME=""
BACK_NAME=""

OPT_STR=":f:b:"

while getopts $OPT_STR option
do
    case $option in 
	f  ) FILE_NAME=$OPTARG;;
	b  ) BACK_NAME=$OPTARG;;
    esac
done


shift $((OPTIND - 1))

if [[ $# -eq 0 ]]
then
    if [[ -z $FILE_NAME ]]
    then
	log_err "将 \"${COMMAND_NAME}\" 作为管道中的最后一个命令使用时必须指定文件名"
	print_usage
	exit 65
    fi
else
    if ! type "$1" &>/dev/null
    then
	log_err "第一参数必须是一个可执行的程序"
	print_usage
	exit 65	
    fi
    
    if [[ ! -f "${!#}" ]]
    then
	log_err "文件 \"${!#}\" 不存在或者它不是一个文件"
	print_usage
	exit 65
    elif [[ -z $FILE_NAME ]]
    then
	FILE_NAME=${!#}
    fi    
fi


TEMP_FILE_NAME=${FILE_NAME}.$RANDOM.~$$~
while [[ -e "$TEMP_FILE_NAME" ]]
do
    TEMP_FILE_NAME=${FILE_NAME}.$RANDOM.~$$~
done
: > "$TEMP_FILE_NAME"

if [[ $# -eq 0 ]]
then
    cat > "$TEMP_FILE_NAME"
else
    for i in "$@"
    do
	COMMAND="${COMMAND} \"$i\""
    done    
    eval "$COMMAND" > "$TEMP_FILE_NAME"
fi

if [[ -n $BACK_NAME ]]
then
    mv "$FILE_NAME" "${FILE_NAME}${BACK_NAME}"
fi

mv "$TEMP_FILE_NAME" "$FILE_NAME"


#!/bin/bash


##########################################################################
#
# i -f my_text_file -b .bak iconv -f UTF-8 my_text_file
# i -f my_text_file  iconv -f UTF-8 my_text_file
# i iconv -f UTF-8 my_text_file
# 
# cat my_text_file  | cut -d' ' -f 2 | i -f my_text_file -b .bak
# cat my_text_file  | cut -d' ' -f 2 | i -f my_text_file
#
#########################################################################

COMMAND_NAME=$(basename $0)

function print_usage() {
    cat <<EOF >&2

USAGE: ${COMMAND_NAME} -f <被修改的文件名> -b <备份文件的后缀名> [文本过滤命令]

    -f <被修改的文件名>   用户指定被修改的文件的文件名，当 ${COMMAND_NAME} 被用作管道中的
                          最后一个命令时，则必须使用此选项指定文件名
    -b <备份文的后缀名>   当不指定备份文件后缀名时，将不产生备份文件

Example:

    1. ${COMMAND_NAME} -f my_text_file -b .bak iconv -t GBK my_text_file
       先将 my_text_file 备份为 my_text_file.bak，再将其转换为 GBK 编码

    2. ${COMMAND_NAME} -f my_text_file  iconv -t GBK my_text_file
       将 my_text_file 转换为 GBK 编码，不产生备份文件

    3. ${COMMAND_NAME} iconv -f UTF-8 my_text_file
       此命令的结果同第 2 条
       当 ${COMMAND_NAME} 不用在管道中时，并且没有通过 -f 选项指定文件名，则最后
       一个参数将被认为是被修改的文件名

    4. cat my_text_file  | cut -d' ' -f 2 | ${COMMAND_NAME} -f my_text_file -b .bak
       先将 my_text_file 备份为 my_text_file.bak，再将其除第2个字段的数据删除
       当 ${COMMAND_NAME} 被用作管道中的最后一个命令时必须指定被修改的文件名       
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
	COMMAND="${COMMAND} '$i'"
    done    
    eval "$COMMAND" > "$TEMP_FILE_NAME"
fi

if [[ -n $BACK_NAME ]]
then
    mv "$FILE_NAME" "${FILE_NAME}${BACK_NAME}"
fi

mv "$TEMP_FILE_NAME" "$FILE_NAME"


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

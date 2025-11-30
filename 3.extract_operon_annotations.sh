#!/bin/bash

# 逐行读取4243.list中的路径
while IFS= read -r path; do
    # 检查路径是否存在
    if [ ! -d "$path" ]; then
        echo "Path $path does not exist."
        continue
    fi

    # 定义 output.fasta 的文件路径
    fasta_file="$path/output.fasta"

    # 检查 output.fasta 文件是否存在
    if [ ! -f "$fasta_file" ]; then
        echo "$fasta_file not found."
        continue
    fi

    # 处理 output.fasta 文件，提取蛋白质名，并在对应的 .faa 文件中查找
    grep ">" "$fasta_file" | sed 's/>//g' | sed 's/_combined//g' | while read -r protein; do
        faa_file="$path/$protein.faa"

        # 检查 .faa 文件是否存在
        if [ ! -f "$faa_file" ]; then
            echo "$faa_file not found."
        else
            # 在输出最开头添加 {}.faa 文件提示，并去掉空行
            echo -n "$faa_file: "
            grep ">" "$faa_file" | tr "\n" " " | sed 's/ $/\n/' | grep -v '^$'
        fi
    done
done < "4243.list"


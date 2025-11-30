#!/bin/bash

# 读取4243.list中的每一个路径
while IFS= read -r path; do
    # 检查路径是否存在
    if [ ! -d "$path" ]; then
        echo "Path $path does not exist."
        continue
    fi

    fasta_file="$path/output.fasta"

    # 检查output.fasta文件是否存在
    if [ ! -f "$fasta_file" ]; then
        echo "$fasta_file not found."
        continue
    fi

    # 从output.fasta中提取蛋白质名，并在相应的 .faa 文件中统计 ">” 的出现次数
    grep ">" "$fasta_file" | sed 's/>//g' | sed 's/_combined//g' | while read -r protein; do
        faa_file="$path/$protein.faa"

        # 检查 .faa 文件是否存在
        if [ ! -f "$faa_file" ]; then
            echo "$faa_file not found."
        else
            # 统计 .faa 文件中以 ">" 开头的行数
            count=$(grep ">" -c "$faa_file")
            echo "$faa_file: $count"
        fi
    done
done < "4243.list"


#!/bin/bash

# 逐行读取4243.list中的路径
while IFS= read -r path; do
    # 定义 .tsv 文件的路径
    tsv_file="/home/yanqiuLiu/project/defense-system/20240925-e.coli/data/$path/protein_defense_finder_systems.tsv"

    # 检查该路径下的文件是否存在
    if [ -f "$tsv_file" ]; then
        # 输出文件内容，同时在第一列加上路径名 (GCF_xxxxx)
        awk -v prefix="$path" 'BEGIN {FS=OFS="\t"} {print prefix, $0}' "$tsv_file"
    else
        echo "File $tsv_file not found."
    fi
done < "4243.list"


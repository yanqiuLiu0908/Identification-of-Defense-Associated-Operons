#!/bin/bash

# 读取 xx.list 中的每一行
while read -r line; do
    # 取出每行的第一列 (即 $1)
    ID=$(echo $line | awk '{print $1}')
    
    # 创建log文件路径
    LOG_FILE="/home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/script.log"
    
    # 执行 defense-finder 并存储输出到指定目录
    defense-finder run ${ID}/ncbi_dataset/data/${ID}/protein.faa -o /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID} > "${LOG_FILE}" 2>&1

    # 比较 protein_defense_finder_hmmer.tsv 和 protein_defense_finder_genes.tsv，找出独特的基因
    comm -23 <(cut -f 1 /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/protein_defense_finder_hmmer.tsv | uniq) <(cut -f 2 /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/protein_defense_finder_genes.tsv | uniq) > /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/uniq-genes.list  

    # 复制 test15.sh 并替换文件中的 xxxx 为当前的 $ID
    cp /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/test15.sh /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/ 
    sed -i "s/xxxxx/${ID}/g" /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/test15.sh >> "${LOG_FILE}" 2>&1

    # 执行修改后的 test15.sh 脚本
    sh /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/test15.sh >> "${LOG_FILE}" 2>&1

    # 复制 faa2fasta.sh 并替换文件中的 xxxx 为当前的 $ID
    cp /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/faa2fasta.sh /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/ >> "${LOG_FILE}" 2>&1
    sed -i "s/xxxxx/${ID}/g" /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/faa2fasta.sh >> "${LOG_FILE}" 2>&1

    # 执行修改后的 faa2fasta.sh 脚本
    sh /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/faa2fasta.sh 

    # 合并 fasta 文件并运行 cd-hit
    cat /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/*.fasta > /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/input.fasta
    cd-hit -i /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/input.fasta -o /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/${ID}/output.fasta -c 1 -n 5 >> "${LOG_FILE}" 2>&1

done < 4243.list


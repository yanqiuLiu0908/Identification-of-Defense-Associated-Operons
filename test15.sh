#!/bin/bash

# 输入参数
GFF_FILE="/home/yanqiuLiu/project/defense-system/20240925-e.coli/data/xxxxx/ncbi_dataset/data/xxxxx/genomic.gff"
PROTEIN_FILE="/home/yanqiuLiu/project/defense-system/20240925-e.coli/data/xxxxx/ncbi_dataset/data/xxxxx/protein.faa"
GENE_LIST="/home/yanqiuLiu/project/defense-system/20240925-e.coli/data/xxxxx/uniq-genes.list"

# 读取基因列表文件，逐个处理每个基因
while read -r TARGET_GENE; do
    echo "Processing gene: $TARGET_GENE"

    # 提取靶基因的位置及上下三行，并保存到临时文件
    temp_info_file=$(mktemp)
    grep "CDS" "$GFF_FILE" | grep -A 5 -B 5 "$TARGET_GENE"|sed 's/Protein Homology/Protein-Homology/g' > "$temp_info_file"

    if [[ ! -s "$temp_info_file" ]]; then
        echo "Error: Target gene $TARGET_GENE not found in GFF file."
        rm "$temp_info_file"
        continue
    fi

    TARGET_START=$(grep "$TARGET_GENE" "$temp_info_file" | awk '{print $4}')
    TARGET_END=$(grep "$TARGET_GENE" "$temp_info_file" | awk '{print $5}')
    TARGET_STRAND=$(grep "$TARGET_GENE" "$temp_info_file" | awk '{print $7}')

    echo "Target start: $TARGET_START, Target end: $TARGET_END, Target strand: $TARGET_STRAND"
    echo "Contents of $temp_info_file:"
    cat "$temp_info_file"

    temp_file=$(mktemp)
    grep -v "^#" "$temp_info_file" | awk -v target_start="$TARGET_START" -v target_end="$TARGET_END" -v strand="$TARGET_STRAND" '
    {
        gene_name = gensub(/.*Name=([^;]+).*/, "\\1", "g", $9);
        #gene_name = gensub(/^cds-/, "", "g", gene_name);
        gene_start = $4;
        gene_end = $5;

        if ($3 == "CDS" && $7 == strand) {
            print gene_name, gene_start, gene_end;
        }
    }' > "$temp_file"

    rm "$temp_info_file"

    echo "Contents of $temp_file:"
    cat "$temp_file"

    # 初始化两个数组分别存储上游和下游基因
    UPSTREAM_GENES=()
    DOWNSTREAM_GENES=()

    # 先将目标基因存入下游数组，因为向下查找会从目标基因开始
    DOWNSTREAM_GENES+=("$TARGET_GENE")

    # 创建一个用于存储反向结果的临时文件
    temp_tac_file=$(mktemp)
    tac "$temp_file" > "$temp_tac_file"

    # 向上查找符合条件的基因
    echo "Searching upwards..."
    found_target=0
    previous_end="$TARGET_START"
    while read -r gene_name gene_start gene_end; do
        if [[ $found_target -eq 0 && "$gene_name" == "$TARGET_GENE" ]]; then
            found_target=1
            echo "Found target gene $gene_name in upwards search."
            continue
        fi

        if [[ $found_target -eq 1 ]]; then
            overlap=$((previous_end - gene_end))
            echo "Checking gene $gene_name (upwards): Overlap is $overlap"

            if (( overlap >= -100 && overlap <= 100 )); then
                UPSTREAM_GENES+=("$gene_name")
                echo "Added gene (upwards): $gene_name"
                previous_end="$gene_start"  # 更新上一基因的结束位置
                echo "UPSTREAM_GENES after adding: ${UPSTREAM_GENES[@]}"
            else
                echo "Gene $gene_name (upwards) does not meet overlap criteria: $overlap, but retaining previously found genes."
                break
            fi
        fi
    done < "$temp_tac_file"  # 从反向排序的临时文件读取

    # 删除反向排序的临时文件
    rm "$temp_tac_file"

    # 向下查找符合条件的基因
    echo "Searching downwards..."
    found_target=0
    next_start="$TARGET_END"
    while read -r gene_name gene_start gene_end; do
        if [[ $found_target -eq 0 && "$gene_name" == "$TARGET_GENE" ]]; then
            found_target=1
            echo "Found target gene $gene_name in downwards search."
            continue
        fi

        if [[ $found_target -eq 1 ]]; then
            overlap=$((gene_start - next_start))
            echo "Checking gene $gene_name (downwards): Overlap is $overlap"

            if (( overlap >= -100 && overlap <= 100 )); then
                DOWNSTREAM_GENES+=("$gene_name")
                echo "Added gene (downwards): $gene_name"
                next_start="$gene_end"
                echo "DOWNSTREAM_GENES after adding: ${DOWNSTREAM_GENES[@]}"
            else
                echo "Gene $gene_name (downwards) does not meet overlap criteria: $overlap, but retaining previously found genes."
                break
            fi
        fi
    done < "$temp_file"

    rm "$temp_file"

    # 打印调试信息，检查上游和下游数组的内容
    echo "UPSTREAM_GENES: ${UPSTREAM_GENES[@]}"
    echo "DOWNSTREAM_GENES: ${DOWNSTREAM_GENES[@]}"

    # 合并上游和下游的基因，先上游再下游
    CDS_GENES=("${UPSTREAM_GENES[@]}" "${DOWNSTREAM_GENES[@]}")

    # 对合并后的基因排序
    CDS_GENES=$(printf "%s\n" "${CDS_GENES[@]}" | sort)

    # 如果需要重新将结果转回数组，可以这样
    CDS_GENES=($(echo "${CDS_GENES}"))

    # 输出找到的符合条件的基因
    echo "Found CDS Genes:"
    for gene in "${CDS_GENES[@]}"; do
        echo "$gene"
    done

    # 如果找到的基因数量超过1个，则提取并保存蛋白质序列
    if [[ ${#CDS_GENES[@]} -gt 1 ]]; then
        OUTPUT_FILE=/home/yanqiuLiu/project/defense-system/20240925-e.coli/data/xxxxx/"${TARGET_GENE}.faa"
        echo "Protein sequences will be saved to $OUTPUT_FILE"
        {
            for gene in "${CDS_GENES[@]}"; do
                awk -v gene="$gene" -v RS=">" -v ORS="" '
                $0 ~ gene {
                    print ">" $0;
                }' "$PROTEIN_FILE"
                echo
            done
        } > "$OUTPUT_FILE"

        sequence_count=$(grep -c "^>" "$OUTPUT_FILE")
        echo "Number of sequences in $OUTPUT_FILE: $sequence_count"
    else
        echo "No CDS genes found for $TARGET_GENE."
    fi

done < "$GENE_LIST"


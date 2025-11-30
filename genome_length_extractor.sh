while read line; do
    grep sequence-region $line/ncbi_dataset/data/$line/genomic.gff | awk '$4>3000000{print "'$line'", $4}'
done < 4243.list


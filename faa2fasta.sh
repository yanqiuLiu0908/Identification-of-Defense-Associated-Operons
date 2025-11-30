for file in /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/xxxxx/*.faa; do
  # 获取文件名去掉.faa后缀，用于标识输出的fasta条目名称
  basename=$(basename "$file" .faa)
  
  # 将该文件中的所有蛋白质序列连成一条长的序列，并输出到新的fasta文件中
  awk '/^>/ {next} {seq = seq $0} END {print ">" "'$basename'_combined"; print seq}' "$file" > /home/yanqiuLiu/project/defense-system/20240925-e.coli/data/xxxxx/"${basename}_combined.fasta"
done


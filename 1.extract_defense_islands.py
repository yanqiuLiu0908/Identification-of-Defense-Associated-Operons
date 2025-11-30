import os

# 读取 4243.list 文件中的 GCF 路径
with open("4243.list", "r") as list_file:
    paths = [line.strip() for line in list_file.readlines()]

# 遍历每个 GCF 路径
for path in paths:
    fasta_file = os.path.join(path, "output.fasta")
    tsv_file = os.path.join(path, "protein_defense_finder_hmmer.tsv")

    # 检查文件是否存在
    if not os.path.exists(fasta_file) or not os.path.exists(tsv_file):
        print(f"Files not found for path: {path}")
        continue

    # 使用 sed 命令提取蛋白质名并去掉 _combined
    try:
        protein_names = os.popen(f"sed -n 's/>//p' {fasta_file} | sed 's/_combined//g'").read().splitlines()
    except Exception as e:
        print(f"Error processing fasta file in path: {path}")
        continue

    # 打开并读取TSV文件
    with open(tsv_file, "r") as tsv:
        tsv_lines = tsv.readlines()

    # 建立字典来存储 hit_id、gene_name 和最小 e-value 的对应关系
    hit_to_best_gene = {}
    for line in tsv_lines[1:]:  # 跳过标题行
        columns = line.strip().split("\t")
        hit_id = columns[0]  # 第一列是 hit_id
        gene_name = columns[4]  # 第五列是 gene_name
        e_value = float(columns[5])  # 第六列是 e-value
        
        # 如果该蛋白质第一次出现，或当前 e-value 更小，则更新字典
        if hit_id not in hit_to_best_gene or e_value < hit_to_best_gene[hit_id][1]:
            hit_to_best_gene[hit_id] = (gene_name, e_value)

    # 打印匹配结果，格式为：路径名 蛋白质名(hit_id) gene_name e-value
    for protein in protein_names:
        if protein in hit_to_best_gene:
            gene_name, e_value = hit_to_best_gene[protein]
            print(f"{path} {protein} {gene_name} {e_value}")
        else:
            print(f"{path} {protein} No match found")


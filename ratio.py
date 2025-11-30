import pandas as pd
import numpy as np
import subprocess
import os

def get_position_from_gff(protein_id, gff_file):
    """从GFF文件中获取蛋白质的平均位置"""
    cmd = f"grep 'CDS' {gff_file} | grep '{protein_id}' | awk '{{print int(($4 + $5) / 2)}}' | head -n 1"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    position = result.stdout.strip()
    return int(position) if position else None

def process_hits(uniq_genes_file, gff_file):
    """处理hit蛋白并计算它们的位置"""
    hits_data = []
    with open(uniq_genes_file, 'r') as f:
        for line in f:
            protein_id = line.strip()
            position = get_position_from_gff(protein_id, gff_file)
            if position:
                hits_data.append([protein_id, position])
    return pd.DataFrame(hits_data, columns=['hit_id', 'hit_site'])

def process_defense_systems(defense_systems_file, gff_file):
    """处理防御系统并计算它们的位置"""
    df = pd.read_csv(defense_systems_file, sep='\t')
    defense_data = []
    
    for _, row in df.iterrows():
        beg_pos = get_position_from_gff(row['sys_beg'], gff_file)
        end_pos = get_position_from_gff(row['sys_end'], gff_file)
        if beg_pos and end_pos:
            avg_pos = (beg_pos + end_pos) // 2
            defense_data.append([row['type'], row['sys_beg'], row['sys_end'], avg_pos])
    
    return pd.DataFrame(defense_data, columns=['type', 'sys_beg', 'sys_end', 'position'])

def calculate_circular_distance(hit_site, ds_site, genome_length):
    """计算环形基因组中的最短距离"""
    site1 = abs(hit_site - ds_site)
    site2 = genome_length - site1
    return min(site1, site2)

def calculate_distances(genome_id, gff_file, defense_systems_file, uniq_genes_file, genome_length):
    """为单个基因组计算距离并生成结果"""
    print(f"Processing {genome_id}...")

    # 处理hits和防御系统数据
    hits_df = process_hits(uniq_genes_file, gff_file)
    ds_df = process_defense_systems(defense_systems_file, gff_file)

    if ds_df.empty:
        print(f"Warning: No defense systems found for {genome_id}")
        return None

    # 准备结果列表
    results = []

    for _, hit_row in hits_df.iterrows():
        hit_id = hit_row['hit_id']
        hit_site = hit_row['hit_site']

        # 计算与每个防御系统的距离并按类型存储
        distances_by_type = {}
        for _, ds_row in ds_df.iterrows():
            distance = calculate_circular_distance(hit_site, ds_row['position'], genome_length)
            ds_type = ds_row['type']
            if ds_type not in distances_by_type:
                distances_by_type[ds_type] = []
            distances_by_type[ds_type].append(distance)

        # 计算每种类型的平均距离
        avg_distances = {ds_type: int(np.mean(distances)) 
                        for ds_type, distances in distances_by_type.items()}

        # 计算ratio (距离小于50kb的比例)
        close_systems = sum(1 for d in [min(distances) for distances in distances_by_type.values()] 
                          if d <= 50000)
        ratio = close_systems / len(distances_by_type) if distances_by_type else 0

        # 创建结果行
        row = [genome_id, hit_id, hit_site]
        for ds_type in ds_df['type'].unique():
            row.append(avg_distances.get(ds_type, np.nan))
        row.append(ratio)
        results.append(row)

    # 创建结果DataFrame
    column_names = ['genome', 'hit_id', 'hit_site'] + list(ds_df['type'].unique()) + ['ratio']
    results_df = pd.DataFrame(results, columns=column_names)

    # 保存完整结果到单独的文件
    output_file = f'{genome_id}_ratio.tsv'
    results_df.to_csv(output_file, sep='\t', index=False)
    
    # 打印预览
    print(f"\nPreview of results for {genome_id}:")
    print(results_df.head())

    return results_df[['genome', 'hit_id', 'ratio']]

def process_all_genomes(genome_list_file):
    """处理所有基因组并合并结果"""
    all_results = []

    with open(genome_list_file, 'r') as f:
        for line in f:
            genome_id, genome_length = line.strip().split()
            genome_length = int(genome_length)
            clean_genome_id = genome_id.strip()

            # 构建文件路径
            gff_file = f"../{clean_genome_id}/ncbi_dataset/data/{clean_genome_id}/genomic.gff"
            defense_systems_file = f"../{clean_genome_id}/protein_defense_finder_systems.tsv"
            uniq_genes_file = f"../{clean_genome_id}/uniq-genes.list"

            if not all(os.path.exists(f) for f in [gff_file, defense_systems_file, uniq_genes_file]):
                print(f"Warning: Some files missing for {clean_genome_id}, skipping...")
                continue

            try:
                results_df = calculate_distances(clean_genome_id, gff_file,
                                              defense_systems_file,
                                              uniq_genes_file, genome_length)

                if results_df is not None:
                    all_results.append(results_df)

            except Exception as e:
                print(f"Error processing {clean_genome_id}: {str(e)}")
                continue

    if all_results:
        # 合并所有结果
        combined_results = pd.concat(all_results, ignore_index=True)
        return combined_results
    else:
        raise Exception("No results were generated for any genome")

if __name__ == "__main__":
    genome_list_file = "4243_length.list"

    print("Starting batch processing...")

    try:
        # 生成并合并所有结果
        combined_results = process_all_genomes(genome_list_file)

        # 保存合并结果到4243-ratio.list
        output_file = '4243-ratio.list'
        combined_results.to_csv(output_file, sep='\t', index=False)
        print(f"\nMerged results saved to {output_file}")

    except Exception as e:
        print(f"Error: {str(e)}")

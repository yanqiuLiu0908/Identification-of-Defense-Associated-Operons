#!/usr/bin/env python3

def parse_fasta_header(header):
    # Remove '>' and split by '-'
    parts = header.strip('>').split('-')
    if len(parts) >= 2:
        genome = parts[0]
        hit = parts[1].split('_combined')[0]
        return genome, hit
    return None, None

def process_files(fasta_file, zorya_file, output_file):
    # Read and parse the fasta headers
    genome_hit_pairs = set()  # Changed to set to ensure uniqueness
    with open(fasta_file, 'r') as f:
        for line in f:
            if line.startswith('>'):
                genome, hit = parse_fasta_header(line)
                if genome and hit:
                    genome_hit_pairs.add((genome, hit))

    print(f"Number of unique genome-hit pairs from fasta: {len(genome_hit_pairs)}")
    print("\nFirst few genome-hit pairs:")
    for pair in list(genome_hit_pairs)[:5]:
        print(f"Genome: {pair[0]}, Hit: {pair[1]}")

    # Process Zorya file and write matching lines to output
    matches_found = set()  # To track which pairs we've found matches for

    with open(zorya_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            parts = line.strip().split()
            if len(parts) >= 2:
                current_genome = parts[0]
                current_hit = parts[1]
                current_pair = (current_genome, current_hit)

                if current_pair in genome_hit_pairs and current_pair not in matches_found:
                    outfile.write(line)
                    matches_found.add(current_pair)

    print(f"\nNumber of matches found and written: {len(matches_found)}")

    # Print pairs that weren't found
    missing_pairs = genome_hit_pairs - matches_found
    if missing_pairs:
        print("\nPairs from fasta that weren't found in Zorya file:")
        for pair in missing_pairs:
            print(f"Genome: {pair[0]}, Hit: {pair[1]}")

def main():
    fasta_file = "clustered_50kb_combined.fasta"
    zorya_file = "50kb.xls"
    output_file = "50kb_0.9.xls"

    process_files(fasta_file, zorya_file, output_file)

if __name__ == "__main__":
    main()

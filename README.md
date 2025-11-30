# Identification-of-Defense-Associated-Operons
Harnessing modular defensive domains to discover new anti-phage systems
Run the main pipeline:


**all.sh：**
Calls **test15.sh** to predict operons
Uses **faa2fasta.sh** to merge operon sequences for reducing redundancy;

**ratio.py:**
Calculates % of unique genes within 50kb of defense systems

**cd-hit-grep-line-50kb.py:**
Clusters operons at 90% sequence identity




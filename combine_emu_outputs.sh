#!/bin/bash

# Script to properly combine EMU counts by matching tax_id
cd /blue/duttonc/duttonc/giraffe/superaccuracy/emu_tax_S289_S384

echo "Creating combined counts table with proper row matching..."

# Step 1: Get all unique tax_ids and their taxonomy info across ALL samples
echo "Getting all unique taxa..."
cat S*/S*_merged_for_emu.fastq_rel-abundance.tsv | \
awk -F$'\t' 'NR>1 {print $1"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13}' | \
sort -u > all_unique_taxa.tsv

# Step 2: Create header
printf "tax_id\tspecies\tgenus\tfamily\torder\tclass\tphylum\tclade\tsuperkingdom\tsubspecies\tspecies_subgroup\tspecies_group" > combined_emu_counts.tsv

# Find which samples exist
SAMPLES=()
for i in {289..384}; do
    if [[ -f "S${i}/S${i}_merged_for_emu.fastq_rel-abundance.tsv" ]]; then
        SAMPLES+=("S${i}")
        printf "\tS${i}" >> combined_emu_counts.tsv
    fi
done
printf "\n" >> combined_emu_counts.tsv

echo "Found ${#SAMPLES[@]} samples: ${SAMPLES[*]}"

# Step 3: For each unique tax_id, get counts from each sample
echo "Matching taxa across all samples..."
while IFS=$'\t' read -r tax_id species genus family order class phylum clade superkingdom subspecies species_subgroup species_group; do
    # Print taxonomy info
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" "$tax_id" "$species" "$genus" "$family" "$order" "$class" "$phylum" "$clade" "$superkingdom" "$subspecies" "$species_subgroup" "$species_group" >> combined_emu_counts.tsv
    
    # For each sample, look up this tax_id and get its count
    for sample in "${SAMPLES[@]}"; do
        counts=$(awk -F$'\t' -v tid="$tax_id" '$1==tid {print $14; exit}' "${sample}/${sample}_merged_for_emu.fastq_rel-abundance.tsv")
        if [[ -z "$counts" ]]; then
            counts="0"
        fi
        printf "\t%s" "$counts" >> combined_emu_counts.tsv
    done
    printf "\n" >> combined_emu_counts.tsv
done < all_unique_taxa.tsv

# Step 4: Create CSV version
sed 's/\t/,/g' combined_emu_counts.tsv > combined_emu_counts.csv

# Clean up
rm all_unique_taxa.tsv

echo "Done! Created:"
echo "- combined_emu_counts.tsv"
echo "- combined_emu_counts.csv" 
echo "Total unique taxa: $(tail -n +2 combined_emu_counts.tsv | wc -l)"
echo "Samples included: ${#SAMPLES[@]}"

# Verify the data looks correct
echo ""
echo "First few rows of the combined data:"
head -3 combined_emu_counts.tsv

#!/bin/bash

mkdir -p COMBINED-DATA

for dir in RAW-DATA/DNA*
do
    dna_id=$(basename "$dir")

    culture_name=$(awk -v id="$dna_id" '$1==id {print $2}' RAW-DATA/sample-translation.txt)

    # --- Copy checkm and GTDB files ---
    if [[ -f "$dir/checkm.txt" ]]
    then
        cp "$dir/checkm.txt" "COMBINED-DATA/${culture_name}-CHECKM.txt"
    fi

    if [[ -f "$dir/gtdb.gtdbtk.tax" ]]
    then
        cp "$dir/gtdb.gtdbtk.tax" "COMBINED-DATA/${culture_name}-GTDB-TAX.txt"
    fi

    mag_count=1
    bin_count=1

    for fasta in "$dir"/bins/*.fasta
    do
        file=$(basename "$fasta")

        # --- Handle UNBINNED ---
        if [[ "$file" == "bin-unbinned.fasta" ]]
        then
            cp "$fasta" "COMBINED-DATA/${culture_name}_UNBINNED.fa"
            continue
        fi

        binnr=${file%.fasta}

        # extract completion and contamination
        read complete contamination < <(
            awk -v id="$binnr" '$1==id {print $12, $13}' "$dir/checkm.txt"
        )

        if [[ "$complete" -ge 50 && "$contamination" -le 5 ]]
        then
            type="MAG"
            number=$(printf "%03d" $mag_count)
            ((mag_count++))
        else
            type="BIN"
            number=$(printf "%03d" $bin_count)
            ((bin_count++))
        fi

        cp "$fasta" "COMBINED-DATA/${culture_name}_${type}_${number}.fa"
    done
done

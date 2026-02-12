#!/bin/bash

mkdir -p COMBINED-DATA

for dir in RAW-DATA/DNA*
do
    dna_id=$(basename "$dir")

    # Get culture name from translation file
    culture_name=$(awk -v id="$dna_id" '$1==id {print $2}' RAW-DATA/sample-translation.txt)

    [[ -z "$culture_name" ]] && continue

    # ---- Copy checkm and GTDB files ----
    [[ -f "$dir/checkm.txt" ]] && \
        cp "$dir/checkm.txt" "COMBINED-DATA/${culture_name}-CHECKM.txt"

    [[ -f "$dir/gtdb.gtdbtk.tax" ]] && \
        cp "$dir/gtdb.gtdbtk.tax" "COMBINED-DATA/${culture_name}-GTDB-TAX.txt"

    mag_count=1
    bin_count=1

    for fasta in "$dir"/bins/*.fasta
    do
        [[ -e "$fasta" ]] || continue

        file=$(basename "$fasta")

        # ---- UNBINNED ----
        if [[ "$file" == "bin-unbinned.fasta" ]]
        then
            cp "$fasta" "COMBINED-DATA/${culture_name}_UNBINNED.fa"
            continue
        fi

        binnr="${file%.fasta}"

        # Extract completeness (col 13) and contamination (col 14)
        read complete contamination < <(
            awk -v id="$binnr" '
                NR>2 && $1 ~ id"$" {
                    print $13, $14
                }
            ' "$dir/checkm.txt"
        )

        [[ -z "$complete" || -z "$contamination" ]] && continue

        # ---- One-awk MAG/BIN decision ----
        read type number < <(
            awk -v comp="$complete" -v cont="$contamination" \
                -v m="$mag_count" -v b="$bin_count" '
                BEGIN {
                    if (comp >= 50 && cont <= 5)
                        printf "MAG %03d\n", m
                    else
                        printf "BIN %03d\n", b
                }'
        )

        # Update counters
        [[ "$type" == "MAG" ]] && ((mag_count++)) || ((bin_count++))

        # ---- Rename sequences inside FASTA ----
        awk -v culture="${culture_name}_${type}_${number}" '
            /^>/ {
                count++
                printf(">%s_%03d\n", culture, count)
                next
            }
            { print $0}
        ' $fasta > "COMBINED-DATA/${culture_name}_${type}_${number}.fa"
    done
done

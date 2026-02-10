#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <fasta_file>"
    exit 1
fi

FASTA="$1"

if [ ! -f "$FASTA" ]; then
    echo "Error: File not found: $FASTA"
    exit 1
fi

awk '
BEGIN {
    seq_count = 0
    total_len = 0
    gc_count = 0
    min_len = -1
    curr_len = 0
}
# Header line
/^>/ {
    if (curr_len > 0) {
        seq_count++
        total_len += curr_len
        if (min_len == -1 || curr_len < min_len) min_len = curr_len
        if (curr_len > max_len) max_len = curr_len
    }
    curr_len = 0
    next
}
# Sequence line
{
    line = toupper($0)
    curr_len += length(line)
    gc_count += gsub(/[GC]/, "", line)
}
END {
    # Handle last sequence
    if (curr_len > 0) {
        seq_count++
        total_len += curr_len
        if (min_len == -1 || curr_len < min_len) min_len = curr_len
        if (curr_len > max_len) max_len = curr_len
    }

    avg_len = (seq_count > 0) ? total_len / seq_count : 0
    gc_percent = (total_len > 0) ? (gc_count / total_len) * 100 : 0

    printf "FASTA File Statistics:\n"
    printf "----------------------\n"
    printf "Number of sequences: %d\n", seq_count
    printf "Total length of sequences: %d\n", total_len
    printf "Length of the longest sequence: %d\n", max_len
    printf "Length of the shortest sequence: %d\n", min_len
    printf "Average sequence length: %.2f\n", avg_len
    printf "GC Content (%%): %.2f\n", gc_percent
}
' "$FASTA"

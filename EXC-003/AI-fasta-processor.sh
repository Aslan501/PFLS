#!/usr/bin/env bash

# -----------------------------
# Argument & file checks
# -----------------------------

# Check that exactly one argument (FASTA file) is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <fasta_file>"
    exit 1
fi

FASTA="$1"

# Check that the file exists
if [ ! -f "$FASTA" ]; then
    echo "Error: File not found: $FASTA"
    exit 1
fi

# -----------------------------
# AWK: FASTA parsing & statistics
# -----------------------------
awk '
BEGIN {
    # Counters and accumulators
    seq_count = 0              # Number of sequences
    total_len = 0              # Total length of all sequences
    gc_count = 0               # Total number of G + C bases
    min_len = -1               # Length of the shortest sequence
    max_len = 0                # Length of the longest sequence
    curr_len = 0               # Length of the current sequence
    seq_name = ""              # Name of the current sequence

    # Histogram parameters
    bin_size = 100             # Bin width in bp
}

# -----------------------------
# Header line (new sequence)
# -----------------------------
/^>/ {
    # Finalize the previous sequence (if any)
    if (seq_name != "") {
        seq_len[++seq_count] = curr_len
        total_len += curr_len
        if (min_len == -1 || curr_len < min_len) min_len = curr_len
        if (curr_len > max_len) max_len = curr_len
    }

    # Store new sequence name (remove ">")
    seq_name = substr($0, 2)
    curr_len = 0
    next
}

# -----------------------------
# Sequence lines (only after a header)
# -----------------------------
seq_name != "" {
    line = toupper($0)   # Normalize to uppercase

    # Warn if unusual bases are found (not A/T/G/C/N)
    if (line ~ /[^ATGCN]/) {
        bad = line
        gsub(/[ATGCN]/, "", bad)
        printf "WARNING: Unusual base(s) [%s] in sequence \"%s\"\n", bad, seq_name > "/dev/stderr"
    }

    # Update length and GC count
    curr_len += length(line)
    gc_count += gsub(/[GC]/, "", line)
}

END {
    # -----------------------------
    # Finalize last sequence
    # -----------------------------
    if (seq_name != "") {
        seq_len[++seq_count] = curr_len
        total_len += curr_len
        if (min_len == -1 || curr_len < min_len) min_len = curr_len
        if (curr_len > max_len) max_len = curr_len
    }

    # -----------------------------
    # FASTA validation
    # -----------------------------
    # No headers found → not a FASTA file
    if (seq_count == 0) {
        print "are you sure this is a fasta-file?"
        exit
    }

    # -----------------------------
    # N50 calculation
    # -----------------------------
    # Sort sequence lengths in descending order
    for (i = 1; i <= seq_count; i++) {
        for (j = i + 1; j <= seq_count; j++) {
            if (seq_len[j] > seq_len[i]) {
                tmp = seq_len[i]
                seq_len[i] = seq_len[j]
                seq_len[j] = tmp
            }
        }
    }

    # Cumulative length until ≥ 50% of total length
    target = total_len / 2
    cum = 0
    for (i = 1; i <= seq_count; i++) {
        cum += seq_len[i]
        if (cum >= target) {
            n50 = seq_len[i]
            break
        }
    }

    # -----------------------------
    # Additional metrics
    # -----------------------------
    avg_len = total_len / seq_count
    gc_percent = (gc_count / total_len) * 100

    # -----------------------------
    # Print statistics
    # -----------------------------
    printf "FASTA File Statistics:\n"
    printf "----------------------\n"
    printf "Number of sequences: %d\n", seq_count
    printf "Total length of sequences: %d\n", total_len
    printf "Length of the longest sequence: %d\n", max_len
    printf "Length of the shortest sequence: %d\n", min_len
    printf "Average sequence length: %.2f\n", avg_len
    printf "N50: %d\n", n50
    printf "GC Content (%%): %.2f\n\n", gc_percent

    # -----------------------------
    # Sequence length histogram
    # -----------------------------
    printf "Sequence length distribution (bin size = %d bp):\n", bin_size

    # Assign sequences to bins
    for (i = 1; i <= seq_count; i++) {
        bin = int(seq_len[i] / bin_size)
        bins[bin]++
    }

    # Print histogram
    for (b = 0; b <= int(max_len / bin_size); b++) {
        low = b * bin_size
        high = low + bin_size - 1
        printf "%6d-%-6d | ", low, high
        for (k = 0; k < bins[b]; k++) printf "#"
        printf " (%d)\n", bins[b]
    }
}
' "$FASTA"

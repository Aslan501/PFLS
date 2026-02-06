# EXC-003

echo "FASTA File Statistics:"
echo "----------------------"
echo -n "Number of sequences:"

for fasta in $1
do
    num_sequences=$(grep '>' $fasta | wc -l)

    echo " $num_sequences"


    echo -n "Total length of sequences:"
    #tr-d deletes a character: here it does that new lines are not counted as part of the length
    total_seq_length=$(grep -v '>' $fasta | tr -d '\n' | wc -c)

    echo " $total_seq_length"
    echo -n "Length of the longest sequence:"

    longest_seq_length=$(awk '
        />/ {
        if (seq_length > max) max = seq_length
        seq_length = 0
        next
        }
        {
        seq_length += length($0)
        }
        END {
        if (seq_length > max) max = seq_length
        print max
        }
    ' $fasta)

    echo " $longest_seq_length"
    echo -n "Length of the shortest sequence:"

    shortest_seq_length=$(awk '
        />/ { min=100000000000000000000000
        if (seq_length2 < min) min = seq_length2
        seq_length2 = 0
        next
        }
        {
        seq_length2 += length($0)
        }
        END {
        if (seq_length2 < min) min = seq_length2
        print min
        }
    ' $fasta)

    echo " $shortest_seq_length"
    echo -n "Average sequence length:"

    anz=$(awk 'BEGIN{count = 0} />/ {count = count + 1} END{print count}' $fasta)
    average_seq_length=$(echo "scale=2; $total_seq_length / $anz" | bc -l)

    echo " $average_seq_length"
    echo -n "GC Content (%):"

    GC=$(awk '!/>/{gc_count += gsub(/[GgCc]/, "", $0)} END {print gc_count}' $fasta)
    GC_percent=$(echo "scale=2; 100 * $GC / $total_seq_length" | bc -l)

    echo " $GC_percent"
done
# -------------------------------------------------------------
# Script purpose: Select optimal trimming positions for forward
#                 and reverse reads using FIGARO
#
# Inputs:
#   * Primer-removed fastq files
#   * List of sample names ("sample_names.txt")
#
# Main output:  JSON file containing ranking of best pairs of forward
#               and reverse trim positions ("trimParameters.json")
#
# Arguments:
#   * Name of sequencing run ("dekas12"" or "dekas13")
#
# To run on dekas12: bash figaro.sh dekas12 223
# To run on dekas13: bash figaro.sh dekas13 273
# -------------------------------------------------------------

# Set sequencing run and expected read length from arguments
SEQ_RUN=$1
EXPECTED_LEN=$2

# Change directories
cd ../data/$SEQ_RUN/cutadapt

# Extract max and min read lengths from all trimmed files
for f in `cat sample_names.txt`; do
  # Unzip forward/reverse fastq into temporary files
  gunzip -c "$f"_R1_001_CUTADAPT.fastq.gz > r1.fastq
  gunzip -c "$f"_R2_001_CUTADAPT.fastq.gz > r2.fastq

  # Extract max/min read length
  prinseq-lite.pl -fastq r1.fastq -stats_len |\
  grep 'max\|min' >> ./log/prinseq_log.txt

  prinseq-lite.pl -fastq r2.fastq -stats_len |\
  grep 'max\|min' >> ./log/prinseq_log.txt
done

# Remove temp files
rm r1.fastq
rm r2.fastq

# Check all read lengths are identical and match expected length
TRIMMED_LEN=$(cut -f3 ./log/prinseq_log.txt | uniq)
if [ "$TRIMMED_LEN" == "$EXPECTED_LEN" ]; then
  echo "Success! Length of trimmed reads are identical and equal to specified length. Proceeding to FIGARO."; else
  echo "Warning! Length of trimmed reads are not identical and/or not equal to specified length. Inspect cutadapt output before proceeding to FIGARO."; fi
  
# Rename files for FIGARO
rename _CUTADAPT.fastq.gz .fastq.gz  *.fastq.gz
if [ "$SEQ_RUN" == "dekas12" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/-EP/-EP-CUTADAPT/')"; done
elif [ "$SEQ_RUN" == "dekas13" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/_/-/; s/_/-/' |\
    sed 's/_EP/-EP-CUTADAPT/')"; done
fi

# Make figaro output directory
mkdir ../figaro

# Run FIGARO
figaro.py \
  -i . \
  -o ../figaro \
  -a 370 \
  -f 1 \
  -r 1 \
  -m 28

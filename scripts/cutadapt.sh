# -------------------------------------------------------------
# Script purpose: Remove primer sequences using cutadapt
#
# Input:  Raw paired-end fastq files
#
# Outputs:
#   * Primer-trimmed fastq files
#   * A tab-delimited summary of run statistics ("cutadapt_log.txt")
#
# Arguments:
#   * Name of sequencing run ("dekas12"" or "dekas13")
#   * Expected read length after primer removal
#
# To run on dekas12: bash cutadapt.sh dekas12 223
# To run on dekas13: bash cutadapt.sh dekas13 273
# -------------------------------------------------------------

# Set sequencing run and expected read length from arguments
SEQ_RUN=$1
EXPECTED_LEN=$2

# Set path variables
RAW_PATH=$(echo "../data/$SEQ_RUN/raw")
CUT_PATH=$(echo "../data/$SEQ_RUN/cutadapt")

# Create new directory
mkdir -p $CUT_PATH/log

# Create file of sample names to loop through
ls "$RAW_PATH"/*.fastq.gz |\
  sed 's/_R1_001.fastq.gz//' |\
  sed 's/_R2_001.fastq.gz//' |\
  sed 's/.*\///' | uniq > "$CUT_PATH"/sample_names.txt

# Loop through samples running cutadapt and print to log
for f in `cat "$CUT_PATH"/sample_names.txt`; do
  cutadapt \
    --report=minimal \
    -g GGHAARGGHGGHATHGGNAARTC \
    -G GGCATNGCRAANCCVCCRCANAC \
    --discard-untrimmed \
    --max-n=0 \
    --match-read-wildcards \
    -e 0.1 \
    -m $EXPECTED_LEN -M $EXPECTED_LEN \
    -o "$CUT_PATH"/"$f"_R1_001_CUTADAPT.fastq.gz \
    -p "$CUT_PATH"/"$f"_R2_001_CUTADAPT.fastq.gz \
    "$RAW_PATH"/"$f"_R1_001.fastq.gz "$RAW_PATH"/"$f"_R2_001.fastq.gz > tmp.txt
  
  sed -i '1 s/^/sample\t/' tmp.txt
  sed -i "2 s/^/$f\t/" tmp.txt
  
  cat tmp.txt >> "$CUT_PATH"/log/cutadapt_log.txt; done
  
# Remove tmp file
rm tmp.txt

# Run script to reformat cutadapt log
Rscript ./cutadapt_log_clean.R $SEQ_RUN

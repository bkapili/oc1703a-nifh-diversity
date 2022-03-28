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
#   * Name of sequencing run
#   * Forward primer sequence
#   * Reverse primer sequence
#   * Min. expected read length after primer removal
#   * Max expected read length after primer removal
#
# To run on dekas12: bash cutadapt.sh dekas12 GGHAARGGHGGHATHGGNAARTC GGCATNGCRAANCCVCCRCANAC 223 223 
# To run on dekas13: bash cutadapt.sh dekas13 GGHAARGGHGGHATHGGNAARTC GGCATNGCRAANCCVCCRCANAC 273 273
# To run on dekas01: bash cutadapt.sh dekas01 GTGYCAGCMGCCGCGGTAA CCGYCAATTYMTTTRAGTTT 226 227
# -------------------------------------------------------------

# Set sequencing run and expected read length from arguments
SEQ_RUN=$1
FWD_PRIMER=$2
REV_PRIMER=$3
MIN_LEN=$4
MAX_LEN=$5

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
    -g $FWD_PRIMER \
    -G $REV_PRIMER \
    --discard-untrimmed \
    --max-n=0 \
    --match-read-wildcards \
    -e 0.1 \
    -m $MIN_LEN -M $MAX_LEN \
    -o "$CUT_PATH"/"$f"_R1_001_CUTADAPT.fastq.gz \
    -p "$CUT_PATH"/"$f"_R2_001_CUTADAPT.fastq.gz \
    "$RAW_PATH"/"$f"_R1_001.fastq.gz "$RAW_PATH"/"$f"_R2_001.fastq.gz > "$CUT_PATH"/log/tmp.txt
  
  sed -i '1 s/^/sample\t/' "$CUT_PATH"/log/tmp.txt
  sed -i "2 s/^/$f\t/" "$CUT_PATH"/log/tmp.txt
  
  cat "$CUT_PATH"/log/tmp.txt >> "$CUT_PATH"/log/cutadapt_log.txt; done
  
# Remove tmp file
rm "$CUT_PATH"/log/tmp.txt

# Run script to reformat cutadapt log
Rscript ./cutadapt_log_clean.R $SEQ_RUN

# Rename files for FIGARO
cd ../data/$SEQ_RUN/cutadapt

rename _CUTADAPT.fastq.gz .fastq.gz  *.fastq.gz
if [ "$SEQ_RUN" == "dekas12" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/-EP/-EP-CUTADAPT/')"; done
elif [ "$SEQ_RUN" == "dekas13" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/_/-/; s/_/-/' |\
    sed 's/_EP/-EP-CUTADAPT/')"; done
elif [ "$SEQ_RUN" == "dekas01" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/OC01/OC01-CUTADAPT/')"; done
elif [ "$SEQ_RUN" == "dekas02" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/OC2/OC2-CUTADAPT/')"; done
elif [ "$SEQ_RUN" == "dekas03" ]; then
  for file in *; do mv "$file" "$(echo "$file" | sed 's/OC03/OC03-CUTADAPT/')"; done
fi

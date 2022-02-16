# -------------------------------------------------------------
# Script purpose: Summarize forward and reverse read quality scores 
#                 for each sample
#
# Input:  Raw paired-end fastq files
#
# Output: HTML files containing summaries of forward and reverse
#         read quality scores per sample
#
# Arguments:
#   * Name of sequencing run ("dekas12"" or "dekas13")
#
# To run on dekas12: bash fastqc.sh dekas12
# To run on dekas13: bash fastqc.sh dekas13
# -------------------------------------------------------------

# Read argument
SEQ_RUN=$1

# Change directory
cd ../data/$SEQ_RUN/raw

# Run fastqc
fastqc *.fastq.gz

# Move to new directory
mkdir ./fastqc && mv *_fastqc* ./fastqc

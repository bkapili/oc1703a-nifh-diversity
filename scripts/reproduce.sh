# -------------------------------------------------------------
# Script purpose: Execute full pipeline for processing raw reads
#                 up through phyloseq object generation.
#
# Notes:          See individual scripts for more information
#                 about each step.
# -------------------------------------------------------------

# Run fastqc
bash fastqc.sh dekas12
#bash fastqc.sh dekas13

# Trim primers
bash cutadapt.sh dekas12 223
#bash cutadapt.sh dekas13 273

# Determine optimal trim positions
bash figaro.sh dekas12 223
#bash figaro.sh dekas13 273

# Infer ASVs
Rscript dada2.R dekas12
#Rscript dada2.R dekas13

# Place ASVs of nifH reference tree
#bash sepp.sh

# Prune off-target ASVs
#Rscript prune_off_target_asvs.R

# Infer taxonomy for nifH ASVs
#Rscript ppit.R

# Remove contaminant ASVs
#Rscript decontam.R

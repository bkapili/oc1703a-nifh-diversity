# -------------------------------------------------------------
# Script purpose: Execute full pipeline for processing raw reads
#                 up through phyloseq object generation.
#
# Notes:          See individual scripts for more information
#                 about each step.
# -------------------------------------------------------------

# Run fastqc
bash fastqc.sh dekas12 &
bash fastqc.sh dekas13 &
bash fastqc.sh dekas01 &
bash fastqc.sh dekas02 &
bash fastqc.sh dekas03 &
wait

# Trim primers
bash cutadapt.sh dekas12 GGHAARGGHGGHATHGGNAARTC GGCATNGCRAANCCVCCRCANAC 223 223 &
bash cutadapt.sh dekas13 GGHAARGGHGGHATHGGNAARTC GGCATNGCRAANCCVCCRCANAC 273 273 &
bash cutadapt.sh dekas01 GTGYCAGCMGCCGCGGTAA CCGYCAATTYMTTTRAGTTT 226 227 &
bash cutadapt.sh dekas02 GTGYCAGCMGCCGCGGTAA CCGYCAATTYMTTTRAGTTT 226 227 &
bash cutadapt.sh dekas03 GTGYCAGCMGCCGCGGTAA CCGYCAATTYMTTTRAGTTT 226 227 &
wait

# Infer ASVs
Rscript dada2.R dekas12 210 190 330 370 &
Rscript dada2.R dekas13 220 190 330 370 &
Rscript dada2.R dekas01 220 180 368 378 &
Rscript dada2.R dekas02 220 180 368 378 &
Rscript dada2.R dekas03 220 180 368 378 &
wait

# Merge phyloseq objects
Rscript merge_phylo.R 16S &
Rscript merge_phylo.R nifH &
wait

# Place ASVs of nifH reference tree
#bash sepp.sh dekas12 3

# Infer taxonomy for nifH ASVs
#Rscript ppit.R dekas12 1 &
#Rscript ppit.R dekas12 2 &
#Rscript ppit.R dekas12 3 &
#wait
#Rscript ppit_compile.R dekas12

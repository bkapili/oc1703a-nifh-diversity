# -------------------------------------------------------------
# Script purpose: Infer ASVs using DADA2
#
# Inputs:
#   * Primer-removed paired-end fastq files
#   * FIGARO output of ranked trimming positions ("trimParameters.json")
#   * Sample metadata ("SampleID_ExperimentID.csv")
#   * Tab-delimited summary of cutadapt statistics ("cutadapt_log.txt")
#
# Main output:  Phyloseq object w/ sample metadata, ASV table,
#               and sequences ("psRaw.rds")
#
# Additional outputs:
#   * Trimmed and quality-filtered reads
#   * Plots of DADA2 error model
#   * Seqtabs of raw, length_filtered, and length_filtered+chimera_removed merged reads
#   * Updated log of per-sample read tracking after each step
#   * Log of total ASV tracking after each step
#
# Run as:
#   Rscript dada2.R dekas12 210 190 330 370
#   Rscript dada2.R dekas13 220 190 330 370
#   Rscript dada2.R dekas01 220 180 368 378
#   Rscript dada2.R dekas02 220 180 368 378
#   Rscript dada2.R dekas03 220 180 368 378
#
# Notes: Portions of code adapted from DADA2 tutorial (v.1.16)
# (https://benjjneb.github.io/dada2/tutorial.html)
# -------------------------------------------------------------

### Load required packages
# List required packages
cranPackages <- c("BiocManager", "ggplot2", "dplyr", "tidyr", "jsonlite")
biocPackages <- c("phyloseq", "dada2", "Biostrings")

# Install missing CRAN packages
installedCRANPackages <- cranPackages %in% rownames(installed.packages())
if (any(installedCRANPackages == FALSE)) {
  install.packages(cranPackages[!installedCRANPackages],
                   repos='http://cran.us.r-project.org')
}

# Install missing Bioconductor packages
installedBioPackages <- biocPackages %in% rownames(installed.packages())
if (any(installedBioPackages == FALSE)) {
  BiocManager::install(biocPackages[!installedBioPackages])
}

# Load packages
lapply(c(cranPackages, biocPackages), library, character.only = TRUE)

### Read arguments and set working directory
# Read arguments
args <- commandArgs(trailingOnly = TRUE)
runName <- args[1]
trimF <- args[2] %>% as.integer
trimR <- args[3] %>% as.integer
filtMin <- args[4] %>% as.integer
filtMax <- args[5] %>% as.integer
setwd(paste0("../data/", runName))

### Trim and quality-filter reads
# Extract file and sample names
fnFs <- list.files("./cutadapt", pattern = "_L001_R1_001.fastq", full.names = TRUE) %>% sort
fnRs <- list.files("./cutadapt", pattern = "_L001_R2_001.fastq", full.names = TRUE) %>% sort
sampleNames <- sapply(strsplit(basename(fnFs), "-CUTADAPT"), `[`, 1)


# Create directory for filtered reads
dir.create("filtered")

# Set path for future filtered files
filtFs <- file.path("./filtered", paste0(sampleNames, "_F_filt.fastq.gz"))
filtRs <- file.path("./filtered", paste0(sampleNames, "_R_filt.fastq.gz"))
names(filtFs) <- sampleNames
names(filtRs) <- sampleNames

# Read in optimal trim positions and maxEE
#figaroOut <- fromJSON("./figaro/trimParameters.json", flatten = TRUE)

#trimParams <- figaroOut %>%
#  filter(row_number() == 1) %>%
#  pull(trimPosition) %>%
#  unlist

# Trim and quality-filter
out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen = c(trimF, trimR),
                     maxN = 0, maxEE = c(2, 2), truncQ = 2,
                     rm.phix = TRUE, compress = TRUE, multithread = FALSE)

### Model error rates
# Dereplicate reads
derepFs <- derepFastq(filtFs, verbose = TRUE)
derepRs <- derepFastq(filtRs, verbose = TRUE)

# Learn error rates
set.seed(144357)
errF <- learnErrors(derepFs, randomize = TRUE, multithread = TRUE, verbose = TRUE)
errR <- learnErrors(derepRs, randomize = TRUE, multithread = TRUE, verbose = TRUE)

# Export PDF of learned errors
dir.create("supplemental")
pErrF <- plotErrors(errF, nominalQ = TRUE)
pErrR <- plotErrors(errR, nominalQ = TRUE)

ggsave(filename = "./supplemental/learned_errors_F.pdf", plot = pErrF,
       device = "pdf", units = "cm", width = 35, height = 20,
       dpi = 300, useDingbats = FALSE)
ggsave(filename = "./supplemental/learned_errors_R.pdf", plot = pErrR,
       device = "pdf", units = "cm", width = 35, height = 20,
       dpi = 300, useDingbats = FALSE)


### Infer ASVs
dadaFs <- dada(derepFs, err = errF, multithread = TRUE, pool = FALSE)
dadaRs <- dada(derepRs, err = errR, multithread = TRUE, pool = FALSE)


### Create and filter ASV table
# Merge read pairs
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose = TRUE)

# Make ASV table
rawSeqtab <- makeSequenceTable(mergers)

# Remove sequences too short or too long
table(nchar(getSequences(rawSeqtab)))
lenFiltSeqtab <- rawSeqtab[, nchar(colnames(rawSeqtab)) %in% seq(filtMin, filtMax)]

# Remove bimeras
chimFiltSeqtab <- removeBimeraDenovo(lenFiltSeqtab, method = "consensus",
                                    multithread = TRUE, verbose = TRUE)
dim(chimFiltSeqtab)
sum(chimFiltSeqtab)/sum(lenFiltSeqtab)

# Save seqtabs
dir.create("./robjects")
saveRDS(rawSeqtab, "./robjects/rawSeqtab.rds")
saveRDS(lenFiltSeqtab, "./robjects/lenFiltSeqtab.rds")
saveRDS(chimFiltSeqtab, "./robjects/chimFiltSeqtab.rds")


### Track read and ASV retention
# Load cutadapt log
cutLog <- read.table(file = "./cutadapt/log/cutadapt_log.txt", header = TRUE) %>%
  arrange(sample)

# Define function to return the number of unique reads/sequences
getN <- function(x) sum(getUniques(x))

# Apply function to output from each step and store in matrix
readTrack <- cbind(pull(cutLog, in_reads), out, sapply(dadaFs, getN), sapply(dadaRs, getN),
               sapply(mergers, getN), rowSums(lenFiltSeqtab), rowSums(chimFiltSeqtab))

# Rename column names to step names and row names to sample names
colnames(readTrack) <- c("raw", "cutadapt", "filtered", "denoisedF", "denoisedR",
                     "merged", "length_filtered", "chim_filtered")
rownames(readTrack) <- sampleNames

# Write read retention matrix to csv
write.csv(readTrack, file = "./supplemental/read_retention.csv",
          quote = FALSE, row.names = TRUE, col.names = TRUE)

# Record number of ASVs in matrix
asvTrack <- cbind(ncol(rawSeqtab), ncol(lenFiltSeqtab), ncol(chimFiltSeqtab))

# Rename column names to step names
colnames(asvTrack) <- c("merged", "length_filtered", "chim_filtered")

# Write ASV retention matrix to csv
write.csv(asvTrack, file = "./supplemental/asv_retention.csv",
          quote = FALSE, row.names = TRUE, col.names = TRUE)


### Create phyloseq object
# Import sample metadata
sampMetadata <- read.csv(file = paste0("./SampleID_metadata_", runName, ".csv"),
                         header = TRUE,
                         row.names = 1)

# Format ASV table for otu_table class
asvSeqtab <- chimFiltSeqtab
colnames(asvSeqtab) <- paste0("ASV", 1:ncol(asvSeqtab))

# Format sequences for refseq class
seqs <- colnames(chimFiltSeqtab) %>% DNAStringSet()
names(seqs) <- paste0("ASV", 1:length(seqs))

# Build and save phyloseq object
psRaw <- phyloseq(otu_table(asvSeqtab, taxa_are_rows = FALSE),  
               refseq(seqs),
               sample_data(sampMetadata))
saveRDS(psRaw, "./robjects/psRaw.rds")

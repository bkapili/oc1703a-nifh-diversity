# -------------------------------------------------------------
# Script purpose: Write out SEPP input files
#
# Inputs: Raw phyloseq objects from the different sequencing runs
#
# Outputs:
#   * Separate fasta of ASV sequences from each run ("psRaw_ASV_seqs.fasta")
#   * nifH reference alignment from PPIT ("nifH_reference_alignment_v2.fasta")
#   * nifH reference tree from PPIT ("nifH_reference_tree_v2.nwk")
#   * RAxML info file from PPIT ("nifH_reference_RAxML_info_v2.txt")
#
# Notes:    This script is executed within "sepp.sh"
#           Run as: Rscript sepp_input_prep.R 3
# -------------------------------------------------------------

### Load required packages
# List required packages
cranPackages <- c("BiocManager", "ape", "devtools", "dplyr")
biocPackages <- c("phyloseq", "Biostrings")

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

# Install ppit if missing
ppitInstall <- "ppit" %in% rownames(installed.packages())
if (ppitInstall == FALSE) {
  devtools::install_github("BKapili/ppit", build_vignettes = FALSE)
}

# Load packages
lapply(c(cranPackages, biocPackages, "ppit"), library, character.only = TRUE)


### Read arguments and set working directory
batchNum <- commandArgs(trailingOnly = TRUE) %>% as.integer
setwd("../data/nifH")


### Prepare sequences
# Subset to only OC1703A samples
psRaw <- readRDS(file = "./psRaw_nifH.rds")
#metadata <- read.csv(file = "../SampleID_metadata_dekas12.csv", row.names = 1)
#sample_data(psRaw) <- sample_data(metadata)
psOC <- subset_samples(psRaw, project == "OC1703A") %>%
  prune_taxa(taxa_sums(.) > 0, .)

# Remove off-target nifH ASVs
'%!in%' <- function(x,y)!('%in%'(x,y))
offTarget <- read.table(file = "./psOC_nifH_off_target_ASVs.txt") %>% pull(V1)
psOC <- prune_taxa(taxa_names(psOC) %!in% offTarget, psOC)

# Retrieve sequences
seqs <- refseq(psOC)

#writeXStringSet(seqs, filepath = paste0("./psOC_all_ASV_seqs.fasta"), format = "fasta")


### Write out SEPP input files
# Create directories for sepp files
dir.create("./sepp")

# PPIT can't run if tree w/ queries is too big, so
# split up the ASVs into batches
batchSize <- ceiling(length(seqs)/batchNum)
set.seed(735920)
subNames <- sample(names(seqs)) %>% split(., ceiling(seq_along(.)/batchSize))

# Write out chimera-filtered ASV sequences
for(x in 1:batchNum) {
  writeXStringSet(seqs[names(seqs) %in% subNames[[x]]],
                  filepath = paste0("./sepp/psOC_ASV_seqs_", x, ".fasta"), format = "fasta")
}

# Write SEPP input files if missing
if (!dir.exists("./sepp_input")) {
  dir.create("./sepp_input")
  
  # Write out nifH reference alignment
  writeXStringSet(DNAStringSet(ppit::nifH_reference_alignment_v2),
                  filepath = "./sepp_input/nifH_reference_alignment_v2.fasta",
                  format = "fasta")
  
  # Write out nifH reference tree
  write.tree(ppit::nifH_reference_tree_v2, file = "./sepp_input/nifH_reference_tree_v2.nwk")
  
  # Write out RAxML info file
  write.table(ppit::nifH_reference_RAxML_info_v2, file = "./sepp_input/nifH_reference_RAxML_info_v2.txt",
              quote = FALSE, col.names = FALSE, row.names = FALSE)
}

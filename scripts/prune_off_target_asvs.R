# -------------------------------------------------------------
# Script purpose: Remove ASVs that did not align to the target
#                 nifH region.
#
# Inputs:
#   * Decontaminated phyloseq object ("psNoContam.rds")
#   * List of off-target ASVs ("off_target_asvs_to_prune.txt)
#
#
# Outputs:
#   * Fully processed phyloseq object ("psNoContam.rds")
#
# Notes:  Off-target ASVs identified via inspection of the SEPP
#         output alignment ("sepp_alignment.fasta")
# -------------------------------------------------------------

### Load required packages
# List required packages
cranPackages <- c("BiocManager", "dplyr", "tidyr")
biocPackages <- c("phyloseq")

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
lapply(c(cranPackages, biocPackages, "ppit"), library, character.only = TRUE)

### Remove misaligned ASVs
'%!in%' <- function(x,y)!('%in%'(x,y))
offTarget <- read.table(file = "./data/off_target_asvs_to_prune.txt") %>% pull(V1)
psNoContam <- prune_taxa(taxa_names(psNoContam) %!in% offTarget, psNoContam)

# Write phyloseq object
saveRDS(psNoContam, file = "../robjects/psNoContam.rds")


### Add filtering summary to read and ASV retention logs
# Load files
readTrack <- read.csv(file = "../supplemental/read_retention.csv",
                      header = TRUE, row.names = 1)
asvTrack <- read.csv(file = "../supplemental/asv_retention.csv",
                     header = TRUE, row.names = 1)

# Add per-sample reads and total ASVs
readTrack <- mutate(readTrack, offtarget_prune = sample_sums(psNoContam))
asvTrack <- mutate(asvTrack, offtarget_prune = ncol(otu_table(psNoContam)))

# Write to csv
write.csv(readTrack, file = "../supplemental/read_retention.csv", quote = FALSE,
          row.names = TRUE, col.names = TRUE)
write.csv(asvTrack, file = "../supplemental/asv_retention.csv", quote = FALSE,
          row.names = TRUE, col.names = TRUE)
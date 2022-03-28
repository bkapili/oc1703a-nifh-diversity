# -------------------------------------------------------------
# Script purpose: Compile PPIT taxonomic inferences from batches.
#
# Inputs:
#   * Phyloseq object before decontamination ("psRaw.rds")
#   * SEPP output tree ("sepp_placement.nwk")
#   * SEPP output alignment ("sepp_alignment.fasta")
#
# Output: Phyloseq object with taxonomic inferences (overwritten "psRaw.rds")
#
# Arguments:
#   * Name of sequencing run (e.g., dekas12)
#   * Number of batches to split nifH ASVs into (e.g., 3)
#
# Run as: Rscript ppit_compile.R
# -------------------------------------------------------------

### Load required packages
# List required packages
cranPackages <- "dplyr"
biocPackages <- "phyloseq"

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
lapply(c(cranPackages, biocPackages), require, character.only = TRUE)


### Set working directory
setwd("../data/nifH")


### Prepare phyloseq object
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


### Add PPIT inferences to tax_table
# Compile PPIT inferences
files <- list.files("./sepp", full.names = TRUE) %>% grep("tax_table_.*", ., value = TRUE)
tax_table <- lapply(files, read.csv, row.names = 1) %>%
  bind_rows(., .id = "column_label") %>%
  mutate(num = gsub("ASV", "", rownames(.)) %>% as.integer) %>%
  arrange(num) %>%
  select(Domain, Phylum, Class, Order, Family, Genus)

# Add to tax_table slot
tax_table(psOC) <- as.matrix(tax_table)


### Save phyloseq object
saveRDS(psOC, file = "./psOC_nifH.rds")

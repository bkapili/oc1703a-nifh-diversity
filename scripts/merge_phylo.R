# -------------------------------------------------------------
# Script purpose: Merge phyloseq objects from multiple runs
#
# Input:  Length-filtered seqtab objects
#
# Output: Merged, chimera-removed phyloseq objects
#
# Arguments:
#   * Name of marker gene to merge
#
# Run as:
#   Rscript merge_phylo.R 16S
#   Rscript merge_phylo.R nifH
# -------------------------------------------------------------

### Load required packages
# List required packages
cranPackages <- c("BiocManager", "dplyr", "tidyr")
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


### Read argument and set working directory
geneName <- commandArgs(trailingOnly = TRUE)
dirPath <- paste0("../data/", geneName)
if (!dir.exists(dirPath)) { dir.create(dirPath) }
setwd(dirPath)


### Load seqtab
if(geneName == "16S") {
  runNames <- c("dekas01", "dekas02", "dekas03")
} else if(geneName == "nifH") {
  runNames <- c("dekas12", "dekas13")
}
seqtabList <- lapply(paste0("../", runNames, "/robjects/lenFiltSeqtab.rds"), readRDS)


### Merge seqtab
seqtabMerge <- mergeSequenceTables(tables = seqtabList)
rownames(seqtabMerge) <- gsub("-CUTADAPT", "", rownames(seqtabMerge))


### Remove bimeras
chimFiltSeqtab <- removeBimeraDenovo(seqtabMerge, method = "consensus",
                                     multithread = TRUE, verbose = TRUE)
dim(chimFiltSeqtab)
sum(chimFiltSeqtab)/sum(seqtabMerge)


### Assign 16S taxonomy
if(geneName == "16S") {
  tax <- assignTaxonomy(chimFiltSeqtab, "./silva/silva_nr_v132_train_set.fa.gz", multithread = TRUE)
  tax <- addSpecies(tax, "./silva/silva_species_assignment_v132.fa.gz")
}


### Build and save phyloseq object
# Load sample data for sample_data class
sampleData <- lapply(paste0("../", runNames, "/SampleID_metadata_", runNames, ".csv"), read.csv,
                     header = TRUE, row.names = 1) %>%
  bind_rows

# Substitute problematic characters for 16S sample names
# (for some reason only a problem for samples on these runs)
if(geneName == "16S") {
  rownames(sampleData) <- gsub("2\\.5", "2-5", rownames(sampleData))
  rownames(sampleData) <- gsub(" ", "", rownames(sampleData))
}

sampleData <- sampleData[rownames(sampleData) %in% rownames(chimFiltSeqtab),]

# Format ASV table for otu_table class
asvSeqtab <- chimFiltSeqtab
colnames(asvSeqtab) <- paste0("ASV", 1:ncol(asvSeqtab))

# Format sequences for refseq class
seqs <- colnames(chimFiltSeqtab) %>% DNAStringSet()
names(seqs) <- paste0("ASV", 1:length(seqs))

# Format taxonomy table for tax_table class
rownames(tax) <- colnames(asvSeqtab)

# Build phyloseq object
if(geneName == "16S") {
  psRaw <- phyloseq(otu_table(asvSeqtab, taxa_are_rows = FALSE),
                    tax_table(tax),
                    refseq(seqs),
                    sample_data(sampleData))
} else if(geneName == "nifH") {
  psRaw <- phyloseq(otu_table(asvSeqtab, taxa_are_rows = FALSE),
                    refseq(seqs),
                    sample_data(sampleData))
}

# Save
saveRDS(psRaw, paste0("./psRaw_132_", geneName, ".rds"))

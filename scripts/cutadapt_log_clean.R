# -------------------------------------------------------------
# Script purpose: Reformat cutadapt log
#
# Input:    Raw cutadapt log ("cutadapt_log.txt")
#
# Output:   Reformatted cutadapt log with internal column names
#           removed and a new column that reports percent of reads
#           written for each sample
#
# Arguments:
#   * Name of sequencing run ("dekas12"" or "dekas13")
#
# Notes:    This script is executed within "cutadapt.sh"
# -------------------------------------------------------------

# Required packages
cranPackages <- c("dplyr", "tidyr")

# Install missing packages
installedCRANPackages <- cranPackages %in% rownames(installed.packages())
if (any(installedCRANPackages == FALSE)) {
  install.packages(cranPackages[!installedCRANPackages],
                   repos='http://cran.us.r-project.org')
}

# Load packages
lapply(cranPackages, library, character.only = TRUE)

# Read run name
runName <- commandArgs(trailingOnly = TRUE)

# Add percent reads written column
outPath <- paste0("../data/", runName, "/cutadapt/log/cutadapt_log.txt")
df <- read.table(file = outPath, sep = "\t", header = TRUE) %>%
  filter(row_number() %% 2 != 0) %>%
  mutate(percent_written = round(as.integer(out_reads)/as.integer(in_reads)*100, 1)) %>%
  arrange(-percent_written)

# Overwrite existing log
write.table(df, file = outPath, sep = "\t", quote = FALSE,
            col.names = TRUE, row.names = FALSE)

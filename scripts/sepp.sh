# -------------------------------------------------------------
# Script purpose: Place ASVs on reference nifH tree from PPIT
#                 (v.1.2.0) using SEPP for subsequent taxonomic inferencing.
#
# Input:  Phyloseq object containing chimera-removed ASV sequences
#         ("psRaw.rds")
#
# Output: Tree(s) in Newick format of ASVs placed on reference tree
#         ("sepp_placement.nwk").
#
# Notes:  PPIT fails if too many ASVs are tried to infer identity
#         at one time. One of the arguments for this function is
#         to specify how many batches to split the ASVs into.
#
# Arguments:
#   * Number of batches to split nifH ASVs into (e.g., 3)
#
# Run as: bash sepp.sh 3
# -------------------------------------------------------------

# Read arguments
BATCH_NUM=$1

# Prepare necessary input files
Rscript sepp_input_prep.R $BATCH_NUM

# Change directory
cd ../data/nifH/sepp

# Run SEPP
for num in $(eval echo "{1..$BATCH_NUM}"); do
  run_sepp.py \
    -t ../sepp_input/nifH_reference_tree_v2.nwk \
    -r ../sepp_input/nifH_reference_RAxML_info_v2.txt \
    -a ../sepp_input/nifH_reference_alignment_v2.fasta \
    -f psOC_ASV_seqs_$num.fasta \
    -o sepp_$num \
    -d . \
    -seed 5935622
  
  # Convert to Newick format
  guppy tog --xml sepp_"$num"_placement.json
  gotree reformat newick \
    -i sepp_"$num"_placement.tog.xml \
    -f phyloxml \
    -o sepp_"$num"_placement.nwk
done
  
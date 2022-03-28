
<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- badges: start -->

<!-- badges: end -->

## Overview

This repo contains the code to reproduce the processing of raw Illumina
MiSeq data as performed in Kapili *et al.*, in prep. The sections below
provide instructions on how to:

  - Create a `conda` environment for data processing
  - Clone this repo
  - Download the raw data
  - Execute the scripts

### conda environment setup and installations

The code below assumes you already have
[conda](https://docs.conda.io/en/latest/) installed. It will create a
new `conda` environment called `oc1703a_nifh_diversity`, activate it,
and install all the necessary packages (and the specific versions) used
during analysis. The environment with installations will require ~1.6 Gb
of disk space.

``` bash
# Set path for environment
CONDA_PATH=$(echo "SET_PATH_HERE")
CONDA_PATH=$(echo $SCRATCH)

# Create conda environment
conda create --prefix $CONDA_PATH/oc1703a_nifh_diversity
conda activate $CONDA_PATH/oc1703a_nifh_diversity

# Install preprocessing software
conda install -c bioconda fastqc=0.11.9 cutadapt=3.5 \
  prinseq=0.20.4 figaro=1.1.2 sepp=4.4.0 \
  gotree=0.4.2 blast=2.12.0 libgit2=1.3.0

# Install R
conda install -c conda-forge r-base=4.1.1
```

### Clone git repo

The code below will clone this repo into a subdirectory named
`oc1703a-nifh-diversity` in the directory you specify in `REPO_PATH`.

``` bash
# Set path for repo
REPO_PATH=$(echo "SET_PATH_HERE")
REPO_PATH=$(echo $SCRATCH)

# Clone repo
mkdir $REPO_PATH/oc1703a-nifh-diversity
git clone https://github.com/bkapili/oc1703a-nifh-diversity.git $REPO_PATH/oc1703a-nifh-diversity
```

### Download raw data

The code below will download the raw PE300 Illumina MiSeq data into a
new subdirectory of `data` named `raw` and unzip the .fastq files
(required for `prinseq`).

Download nifH

``` bash
# Create raw data subdirectory
cd $REPO_PATH/oc1703a-nifh-diversity
mkdir -p data/dekas12/raw
mkdir -p data/dekas13/raw
mkdir -p data/dekas01/raw
mkdir -p data/dekas02/raw
mkdir -p data/dekas03/raw

# Download data
#! /bin/bash
#
#SBATCH --job-name=rclone
#
#SBATCH --partition=serc
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4GB

rclone copy -L KapiliSherlockToDekas_Sequences:IlluminaSequencingRuns/Dekas12 /scratch/groups/dekas/dekas12


#! /bin/bash
#
#SBATCH --job-name=rclone
#
#SBATCH --partition=serc
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4GB

rclone copy -L KapiliSherlockToDekas_Sequences:IlluminaSequencingRuns/Dekas13 /scratch/groups/dekas/dekas13

# there should be 388 files in dekas12/raw
cp $GROUP_SCRATCH/dekas12/DL12-OC17* $REPO_PATH/oc1703a-nifh-diversity/data/dekas12/raw

# there should be 116 files in dekas13/raw
cp $GROUP_SCRATCH/dekas13/DL13_OC17* $REPO_PATH/oc1703a-nifh-diversity/data/dekas13/raw
cp $GROUP_SCRATCH/dekas13/DL13_MOCK* $REPO_PATH/oc1703a-nifh-diversity/data/dekas13/raw
cp $GROUP_SCRATCH/dekas13/DL13_BLAN* $REPO_PATH/oc1703a-nifh-diversity/data/dekas13/raw
cp $GROUP_SCRATCH/dekas13/DL13_AT36* $REPO_PATH/oc1703a-nifh-diversity/data/dekas13/raw

# Unzip (req'd for prinseq)
#gzip -d *.fastq.gz
```

Download 16S

``` bash
# dekas01
rclone copy -L KapiliSherlockToDekas_Sequences:IlluminaSequencingRuns/Dekas01_Demux.tar.gz /scratch/groups/dekas/dekas01
tar -xvzf /scratch/groups/dekas/dekas01/Dekas01_Demux.tar.gz

# Move all non-16S fastqs to separate directory
cd /scratch/groups/dekas/dekas01/Dekas01_Demux
mkdir not_using
ls | grep -v 'OC01' | while read f; do mv "$f" not_using; done

# Copy remaining fastqs to github repo
# there should be 240 files
cp $GROUP_SCRATCH/dekas01/Dekas01_Demux/*fastq.gz $REPO_PATH/oc1703a-nifh-diversity/data/dekas01/raw

# dekas02
rclone copy -L KapiliSherlockToDekas_Sequences:IlluminaSequencingRuns/Dekas02_Demux.tar.gz /scratch/groups/dekas/dekas02
tar -xvzf /scratch/groups/dekas/dekas02/Dekas02_Demux.tar.gz

# Move all non-16S fastqs to separate directory
cd /scratch/groups/dekas/dekas02/Dekas02_Demux
mkdir not_using
ls | grep -v 'OC2' | while read f; do mv "$f" not_using; done

# Copy remaining fastqs to github repo
# there should be 228 files
cp $GROUP_SCRATCH/dekas02/Dekas02_Demux/*fastq.gz $REPO_PATH/oc1703a-nifh-diversity/data/dekas02/raw

# dekas03 (missing "S4000m-MC03-C6-20cm25cm-cDNA-Rep1-OC03")
rclone copy -L KapiliSherlockToDekas_Sequences:IlluminaSequencingRuns/Dekas03_v2 /scratch/groups/dekas/dekas03

# Move all non-16S fastqs to separate directory
cd /scratch/groups/dekas/dekas03
mkdir not_using
ls | grep -v 'OC03' | while read f; do mv "$f" not_using; done

# Copy remaining fastqs to github repo
# there will be 122 files
cp $GROUP_SCRATCH/dekas03/*fastq.gz $REPO_PATH/oc1703a-nifh-diversity/data/dekas03/raw

# Reformat file names
for file in *; do mv "$file" "$(echo "$file" | sed 's/_/-/; s/_/-/; s/_/-/; s/_/-/; s/_/-/; s/_/-/')"; done
```

Download SILVA (v138.1) and (v132) training sets. We’re also downloading
the older v132 because in v138.1, the taxonomy adopts GTDB taxonomic
scheme, which introduced major inconsistencies with the PPIT reference
database (e.g., Deltaproteobactereia in PPIT reference are
Desulfobacterota in SILVA v138.1).

``` bash
# Create directory
cd $REPO_PATH/oc1703a-nifh-diversity/data/16S
mkdir silva && cd silva

# Download training sets
wget -O silva_nr99_v138.1_train_set.fa.gz https://zenodo.org/record/4587955/files/silva_nr99_v138.1_train_set.fa.gz?download=1
wget -O silva_nr_v132_train_set.fa.gz https://zenodo.org/record/1172783/files/silva_nr_v132_train_set.fa.gz?download=1

wget -O silva_species_assignment_v138.1.fa.gz https://zenodo.org/record/4587955/files/silva_species_assignment_v138.1.fa.gz?download=1
wget -O silva_species_assignment_v132.fa.gz https://zenodo.org/record/1172783/files/silva_species_assignment_v132.fa.gz?download=1
```

### Run scripts

The code in this section will run the script `reproduce.sh`, which
executes all the individual steps in order. In order for it to run
properly, it should be executed directly from the scripts folder. After
it runs, the phyloseq object `psNoContam.rds` is saved in a new
subdirectory named `robjects` that contains the fully processed data.

``` bash
# Change directory
cd $REPO_PATH/oc1703a-nifh-diversity/scripts

# Execute reproduce.sh
bash reproduce.sh
```

Additional information about each script is provided in the block of
comment code at the head of each script.

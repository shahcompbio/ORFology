#!/bin/bash
## activate nf-core conda environment
source $HOME/miniforge3/bin/activate nf-core
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/mini_fa_results
pipelinedir=$HOME/VSCodeProjects/tcdo-orfology
samplesheet=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/minifasta_test.csv
blast_db=/data1/shahs3/reference/ref-sarcoma/blast_databases/uniprot_2024_06_release/uniprot_combined.fasta
mkdir -p ${outdir}
cd ${outdir}

nextflow run tcdo/orfology -r latest \
    -profile arm,docker,test \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
    --blast_db ${blast_db} \
    -resume
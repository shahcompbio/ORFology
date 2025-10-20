#!/bin/bash
## activate nf-core conda environment
source $HOME/miniforge3/bin/activate nf-core
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/251016_PG3_AML_cell_lines_results
pipelinedir=$HOME/VSCodeProjects/tcdo-orfology
samplesheet=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/AML_control_merge_fasta_swiss_GTEx_no_decoys.csv
mkdir -p ${outdir}
cd ${outdir}

nextflow run ${pipelinedir}/main.nf \
    -profile arm,docker \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
    --categorize_proteins \
    -resume

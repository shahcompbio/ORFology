#!/bin/bash
## activate nf-core conda environment
source $HOME/miniforge3/bin/activate env_nf
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/mini_fa_results
pipelinedir=$HOME/VSCodeProjects/orfology
samplesheet=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/minifasta_local_test.csv
mkdir -p ${outdir}
cd ${outdir}

nextflow run ${pipelinedir}/main.nf \
    -profile arm,docker \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
    -resume
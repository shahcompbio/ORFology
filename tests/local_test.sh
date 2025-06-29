#!/bin/bash
## activate nf-core conda environment
source $HOME/miniforge3/bin/activate env_nf
## specify params
outdir=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/results
pipelinedir=$HOME/VSCodeProjects/ORFology
samplesheet=/Users/asherpreskasteinberg/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics/APS032_ORFology_test/test.csv
mkdir -p ${outdir}
cd ${outdir}

nextflow run ${pipelinedir}/main.nf \
    -profile arm,docker,test \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
   -resume
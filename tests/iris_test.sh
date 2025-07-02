#!/bin/bash
#SBATCH --partition=componc_cpu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=36:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=orfology
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=preskaa@mskcc.org
#SBATCH --output=slurm%j_orfology.out

## activate nf-core conda environment
source /home/preskaa/miniforge3/bin/activate nf-core
## specify params
outdir=/data1/shahs3/users/preskaa/AMLproteogenomics/data/APS032_ORFology_cell_lines_uniprot_test/results
samplesheet=$HOME/Library/CloudStorage/OneDrive-MemorialSloanKetteringCancerCenter/AMLproteogenomics//APS032_ORFology_cell_lines_uniprot_test/samplesheet.csv
blast_db=/data1/shahs3/reference/ref-sarcoma/blast_databases/uniprot_2024_06_release/uniprot_combined.fasta
mkdir -p ${outdir}
cd ${outdir}

nextflow run shahcompbio/orfology -r main -latest \
    -profile singularity,slurm \
    -work-dir ${outdir}/work \
    --outdir ${outdir} \
    --input ${samplesheet} \
    --blast_db ${blast_db} \
    -with-report \
    -N preskaa@mskcc.org \
    -resume
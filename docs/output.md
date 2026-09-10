# shahcompbio/orfology: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

Output files are prefixed with the sample or merge name, and with the sample `condition` where one is given. Merged results use the prefixes `all_proteins_merged` (every protein) and `unique_proteins_merged` (only uniquely distinguishable proteins, produced with `--unique_proteins`). Tables named `all+unique_...` join the two.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [pgtools](#pgtools) - Merged protein fastas and info tables
- [classifyproteins](#classifyproteins) - Proteins classified by transcriptomic origin
- [philosopher](#philosopher) - Reference proteome downloaded from UniProt
- [diamond](#diamond) - Protein database and raw BLASTP results
- [blastsummary](#blastsummary) - Annotated BLASTP results
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### pgtools

<details markdown="1">
<summary>Output files</summary>

- `pgtools/`
  - `*_merged.fasta`: protein fasta merged across all samples in the samplesheet.
  - `*_merged_info_table.tsv`: table of the merged proteins, recording which samples and conditions each protein was detected in.
  - `all+unique_proteins_*_info_table.tsv`: the `all` and `unique` info tables joined into one (only with `--unique_proteins`).
  - `*_upset_plot.svg`: UpSet plot of the intersection between input fastas (only with `--plot_upset`).
- `fx2tab/`
  - `info_table.tsv`: tabular representation of the input fasta, used when a single sample is analysed or `--skip_merge` is set.

</details>

Produced by [`tcdo_pg_tools`](https://github.com/shahcompbio/tcdo_pg_tools). With `--unique_proteins`, the `unique_proteins_merged` outputs are restricted to proteins that have a combination of peptides distinguishable from other proteins, based on the `Indistinguishable Proteins` column of the Philosopher tables.

### classifyproteins

<details markdown="1">
<summary>Output files</summary>

- `classifyproteins/`
  - `*_annotated_info_table.tsv`: the info table with a `category` column giving each protein's transcriptomic origin.
  - `*_counts_by_category.csv`: number of proteins in each category.
  - `*_counts_by_category.svg`: plot of those counts.
  - `all+unique_proteins_*_info_table.tsv`: annotated `all` and `unique` tables joined into one.

</details>

Only produced with `--categorize_proteins`. See [the README](../README.md#classify-proteins-by-transcriptomic-origins) for how the categories are assigned.

### philosopher

<details markdown="1">
<summary>Output files</summary>

- `philosopher/`
  - `*.fas`: reference proteome downloaded from UniProt.

</details>

Downloaded by [Philosopher](https://github.com/Nesvilab/philosopher) from the proteome named by `--uniprot_proteome`. Not produced when you supply your own database with `--blast_db`.

### diamond

<details markdown="1">
<summary>Output files</summary>

- `diamond/`
  - `*.dmnd`: the DIAMOND protein database that was searched against. Named `db_prep.dmnd` when built from `--blast_db`.
  - `*.txt`: raw tabular BLASTP results.

</details>

Produced by [DIAMOND](https://github.com/bbuchfink/diamond).

### blastsummary

<details markdown="1">
<summary>Output files</summary>

- `blastsummary/`
  - `*_diamond_blastp.annotated.tsv`: BLASTP results annotated with each protein's category.
  - `*_bitscore_distribution.html`: interactive histogram of the score distribution by category.
- `blastsummary_pgtools_merged/`
  - `*.tsv`: the annotated BLASTP results joined with the merged protein info table. This is the main output table of the pipeline.

</details>

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

The pipeline has special steps which allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

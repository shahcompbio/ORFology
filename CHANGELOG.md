# shahcompbio/orfology: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0 - [2026-08-31]

Initial release of shahcompbio/orfology, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- `pgtools` modules to merge fasta files and Fragpipe output results from multiple samples
- `classifyproteins` modules to classify transcripts by transcriptomic origins
- `diamond blastp` modules to blast proteins against known databases
- `--blast_db` to blast against a protein fasta of your choice instead of downloading a UniProt proteome
- `--categorize_proteins` to classify proteins by transcriptomic origin, and `--unique_proteins` to restrict that analysis to proteins with uniquely distinguishable peptides
- nf-test covering a run with `--blast_db`, `--categorize_proteins` and `--unique_proteins`

### `Fixed`

- unique identifiers in pgtools modules
- `--blast_db` is now actually passed to `DIAMOND_MAKEDB`. It previously referenced an undefined variable, so any run supplying a custom database failed
- proteins with no gene annotation no longer crash `categorize_proteins.py` and `blastsummary.py`. An empty `gene_name` is read as `NaN`, which raised `AttributeError: 'float' object has no attribute 'startswith'` and killed every run using `--categorize_proteins`. Such proteins are now reported as `Uncategorized`
- `--categorize_proteins` no longer requires `--unique_proteins`. The classify subworkflow used to unconditionally join an `all` and a `unique` info table, which fails when only the `all` table exists
- stub blocks in the local modules, which were unedited template boilerplate and emitted files that did not match the declared process outputs

### `Dependencies`

### `Deprecated`

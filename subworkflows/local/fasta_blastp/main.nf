// run diamond blast
include { PGTOOLS_FX2TAB as FX2TAB } from '../../../modules/local/pgtools/fx2tab/main'
include { PHILOSOPHER_DATABASE     } from '../../../modules/local/philosopher/database/main'
include { DIAMOND_MAKEDB           } from '../../../modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTP           } from '../../../modules/nf-core/diamond/blastp/main'
include { BLASTSUMMARY             } from '../../../modules/local/blastsummary/main'
include { CSVTK_JOIN               } from '../../../modules/nf-core/csvtk/join/main'

workflow FASTA_BLASTP {
    take:
    ch_fasta      // channel: [ val(meta), [ fasta ] ]
    blast_db      // path to diamond blast database if it already exists
    info_table_ch // channel: [val(meta), [tsv]]

    main:

    ch_versions = Channel.empty()

    // prepare diamond database for diamond blast
    if (!blast_db) {
        PHILOSOPHER_DATABASE([id: params.uniprot_proteome], params.reviewed, params.isoforms)
        blast_fasta = PHILOSOPHER_DATABASE.out.fasta
        ch_versions = ch_versions.mix(PHILOSOPHER_DATABASE.out.versions)
    }
    else {
        blast_fasta = [[id: 'db_prep'], blast_fasta]
    }
    DIAMOND_MAKEDB(blast_fasta, [], [], [])
    ch_versions = ch_versions.mix(DIAMOND_MAKEDB.out.versions)
    DIAMOND_BLASTP(ch_fasta, DIAMOND_MAKEDB.out.db, 6, [])
    ch_versions = ch_versions.mix(DIAMOND_BLASTP.out.versions)
    // convert fastas to tabular format to pick out proteins missing from blast search
    FX2TAB(ch_fasta.map { meta, fasta -> tuple(meta, fasta, []) })
    ch_versions = ch_versions.mix(FX2TAB.out.versions)
    // summarize blast results
    summary_ch = DIAMOND_BLASTP.out.txt.combine(FX2TAB.out.info_table, by: 0)
    BLASTSUMMARY(summary_ch)
    ch_versions = ch_versions.mix(BLASTSUMMARY.out.versions)
    // join blast info with stats on sample recurrence
    BLASTSUMMARY.out.tsv
        .join(info_table_ch, by: 0)
        .map { meta, blast_tsv, pg_tsv ->
            tuple(meta, [blast_tsv, pg_tsv])
        }
        .set { join_ch }
    CSVTK_JOIN(join_ch)
    ch_versions = ch_versions.mix(CSVTK_JOIN.out.versions.first())

    emit:
    blast_results         = BLASTSUMMARY.out.tsv // channel: [ (meta), tsv]
    blast_pgtools_results = CSVTK_JOIN.out.csv // channel [(meta), csv]
    versions              = ch_versions // channel: [ versions.yml ]
}

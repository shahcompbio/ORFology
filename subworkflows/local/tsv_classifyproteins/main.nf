// classify proteins and merge results
include { CLASSIFYPROTEINS } from '../../../modules/local/classifyproteins/main'
include { CSVTK_JOIN       } from '../../../modules/nf-core/csvtk/join/main'

workflow TSV_CLASSIFYPROTEINS {
    take:
    info_table_ch   // channel: [ val(meta), [ tsv ] ]
    unique_proteins // if filtering for unique proteins

    main:

    ch_versions = Channel.empty()
    tsv_ch = Channel.empty()
    // classify ORFs relative to transcriptomic origins
    CLASSIFYPROTEINS(info_table_ch)
    ch_versions = ch_versions.mix(CLASSIFYPROTEINS.out.versions.first())
    // collect and merge results
    if (unique_proteins) {
        CLASSIFYPROTEINS.out.info_table
            .toSortedList { a, b -> a[0].condition <=> b[0].condition }
            .flatten()
            .collect()
            .map { meta1, all_tsv, _meta2, unique_tsv ->
                tuple(meta1, [all_tsv, unique_tsv])
            }
            .set { join_ch }
        join_ch.view()
        CSVTK_JOIN(join_ch)
        tsv_ch = CSVTK_JOIN.out.csv
        ch_versions = ch_versions.mix(CSVTK_JOIN.out.versions)
    }
    else {
        tsv_ch = CLASSIFYPROTEINS.out.info_table
    }

    emit:
    tsv      = tsv_ch // channel [ meta, tsv]
    versions = ch_versions // channel: [ versions.yml ]
}

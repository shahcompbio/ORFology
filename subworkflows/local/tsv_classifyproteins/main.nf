// classify proteins and merge results
include { CLASSIFYPROTEINS } from '../../../modules/local/classifyproteins/main'
include { CSVTK_JOIN       } from '../../../modules/nf-core/csvtk/join/main'

workflow TSV_CLASSIFYPROTEINS {
    take:
    info_table_ch // channel: [ val(meta), [ tsv ] ]

    main:

    ch_versions = Channel.empty()
    // classify ORFs relative to transcriptomic origins
    CLASSIFYPROTEINS(info_table_ch)
    ch_versions = ch_versions.mix(CLASSIFYPROTEINS.out.versions.first())
    // collect and merge results
    CLASSIFYPROTEINS.out.info_table
        .toSortedList { a, b -> a[0].condition <=> b[0].condition }
        .flatten()
        .collect()
        .map { meta1, all_tsv, _meta2, unique_tsv ->
            tuple(meta1, [all_tsv, unique_tsv])
        }
        .set { join_ch }
    // join_ch.view()
    CSVTK_JOIN(join_ch)
    ch_versions = ch_versions.mix(CSVTK_JOIN.out.versions)

    emit:
    tsv      = CSVTK_JOIN.out.csv // channel [ meta, tsv]
    versions = ch_versions // channel: [ versions.yml ]
}

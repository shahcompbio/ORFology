/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PGTOOLS_MERGERESULTS   } from '../modules/local/pgtools/mergeresults/main'
include { PGTOOLS_MERGEFASTA     } from '../modules/local/pgtools/mergefasta/main'
include { PGTOOLS_FX2TAB         } from '../modules/local/pgtools/fx2tab/main'
include { CSVTK_JOIN             } from '../modules/nf-core/csvtk/join/main'
include { TSV_CLASSIFYPROTEINS   } from '../subworkflows/local/tsv_classifyproteins/main'
include { FASTA_BLASTP           } from '../subworkflows/local/fasta_blastp/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_orfology_pipeline'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ORFOLOGY {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    // skip merge if only one sample in samplesheet
    // determine number of samples
    def lines = file(params.input)
        .readLines()
        .findAll { it && !it.startsWith('#') }

    def sampleList = (lines.size() > 1 ? lines[1..-1] : [])
    println("Found ${sampleList.size()} samples")
    if (params.skip_merge || sampleList.size() == 1) {
        println("Only one sample, skipping merge and peptide filtering steps")
        ch_fasta = ch_samplesheet.map { meta, fasta, quant -> tuple([id: meta.id], fasta) }
        // convert fasta to tabular format
        PGTOOLS_FX2TAB(ch_samplesheet)
        info_table_ch = PGTOOLS_FX2TAB.out.info_table
        ch_versions = ch_versions.mix(PGTOOLS_FX2TAB.out.versions)
    }
    else {
        println("Merging all proteins from multiple samples")
        // collect files from samplesheet
        merge_input_ch = ch_samplesheet
            .collect(flat: false)
            .map { sample ->
                def meta_list = sample.collect { it[0] }
                def fasta_list = sample.collect { it[1] }
                tuple(meta_list, fasta_list)
            }
        PGTOOLS_MERGEFASTA([id: "merged", condition: "all_proteins"], merge_input_ch)
        ch_versions = ch_versions.mix(PGTOOLS_MERGEFASTA.out.versions)
        // fetch output of merge
        ch_fasta = PGTOOLS_MERGEFASTA.out.merged_fasta
        info_table_ch = PGTOOLS_MERGEFASTA.out.info_table
    }
    // filter for unique proteins
    if (params.unique_proteins == true) {
        // merge multiple sample and filter for proteins with unique peptides
        ch_samplesheet
            .first { meta, fasta, quant ->
                meta.quant == true
            }
            .set { quant_ch }
        // quant_ch.view()
        if (quant_ch.size() != 0) {
            println("merge + filtering for uniquely distinguishable proteins")
            // collect files from samplesheet
            // ch_samplesheet.view()
            merge_input_ch = ch_samplesheet
                .collect(flat: false)
                .map { sample ->
                    def meta_list = sample.collect { it[0] }
                    def fasta_list = sample.collect { it[1] }
                    def philosopher_list = sample.collect { it[2] }
                    tuple(meta_list, fasta_list, philosopher_list)
                }
            PGTOOLS_MERGERESULTS([id: 'merged', condition: 'unique_proteins'], merge_input_ch)
            ch_versions = ch_versions.mix(PGTOOLS_MERGERESULTS.out.versions)
            // fetch output of merge
            ch_fasta = ch_fasta.mix(PGTOOLS_MERGERESULTS.out.merged_fasta)
            // make headers in unique proteins fasta the same as the all proteins fasta
            PGTOOLS_MERGEFASTA.out.info_table
                .concat(PGTOOLS_MERGERESULTS.out.info_table)
                .collect()
                .map { meta1, all_tsv, _meta2, unique_tsv ->
                    tuple(meta1, [all_tsv, unique_tsv])
                }
                .set { join_ch }
            // join_ch.view()
            CSVTK_JOIN(join_ch)
            ch_versions = ch_versions.mix(CSVTK_JOIN.out.versions)
            info_table_ch = info_table_ch.mix(PGTOOLS_MERGERESULTS.out.info_table)
        }
    }
    // ch_fasta.view()
    // info_table_ch.view()
    // run classify proteins
    // count proteins by category
    if (params.categorize_proteins == true) {
        TSV_CLASSIFYPROTEINS(info_table_ch)
        ch_versions = ch_versions.mix(TSV_CLASSIFYPROTEINS.out.versions)
    }
    // run diamond blast
    FASTA_BLASTP(ch_fasta, params.blast_db, info_table_ch)
    ch_versions = ch_versions.mix(FASTA_BLASTP.out.versions)
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'orfology_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config = Channel.fromPath(
        "${projectDir}/assets/multiqc_config.yml",
        checkIfExists: true
    )
    ch_multiqc_custom_config = params.multiqc_config
        ? Channel.fromPath(params.multiqc_config, checkIfExists: true)
        : Channel.empty()
    ch_multiqc_logo = params.multiqc_logo
        ? Channel.fromPath(params.multiqc_logo, checkIfExists: true)
        : Channel.empty()

    summary_params = paramsSummaryMap(
        workflow,
        parameters_schema: "nextflow_schema.json"
    )
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml')
    )
    ch_multiqc_custom_methods_description = params.multiqc_methods_description
        ? file(params.multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description)
    )

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true,
        )
    )

    MULTIQC(
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        [],
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions // channel: [ path(versions.yml) ]
}

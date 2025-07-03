/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PGTOOLS_MERGERESULTS     } from '../modules/local/pgtools/mergeresults/main'
include { PGTOOLS_FX2TAB ; PGTOOLS_FX2TAB as FX2TAB } from '../modules/local/pgtools/fx2tab/main'
include { PHILOSOPHER_DATABASE     } from '../modules/local/philosopher/database/main'
include { DIAMOND_MAKEDB           } from '../modules/nf-core/diamond/makedb/main'
include { DIAMOND_BLASTP           } from '../modules/nf-core/diamond/blastp/main'
include { CLASSIFYPROTEINS         } from '../modules/local/classifyproteins/main'
include { BLASTSUMMARY             } from '../modules/local/blastsummary/main'
include { MULTIQC                  } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap         } from 'plugin/nf-schema'
include { paramsSummaryMultiqc     } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText   } from '../subworkflows/local/utils_nfcore_orfology_pipeline'


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
        println("Only one sample in samplesheet, skipping merge step")
        ch_fasta = ch_samplesheet.map { meta, fasta, quant -> tuple([id: meta.id], fasta) }
        // convert fasta to tabular format
        PGTOOLS_FX2TAB(ch_samplesheet)
        info_table_ch = PGTOOLS_FX2TAB.out.info_table
        ch_versions = ch_versions.mix(PGTOOLS_FX2TAB.out.versions)
    }
    else {
        // merge multiple sample
        ch_samplesheet
            .first { meta, fasta, quant ->
                meta.quant == true
            }
            .set { quant_ch }
        // quant_ch.view()
        if (quant_ch.size() != 0) {
            println("quantification from philosopher present, filtering for proteins with unique peptides")
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
            PGTOOLS_MERGERESULTS([id: 'merge'], merge_input_ch)
            ch_versions = ch_versions.mix(PGTOOLS_MERGERESULTS.out.versions)
            // fetch output of merge
            ch_fasta = PGTOOLS_MERGERESULTS.out.merged_fasta
            info_table_ch = PGTOOLS_MERGERESULTS.out.info_table
        }
    }
    // count proteins by category
    if (params.categorize_proteins) {
        CLASSIFYPROTEINS(info_table_ch)
        ch_versions = ch_versions.mix(CLASSIFYPROTEINS.out.versions)
    }
    // prepare diamond database for diamond blast
    if (!params.blast_db) {
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
    // skip this for now, will revisit later
    // cat_ch = ch_fasta.map { meta, fasta -> tuple(meta, [fasta, params.blast_db]) }
    // CAT_CAT(cat_ch)
    // ch_versions = ch_versions.mix(CAT_CAT.out.versions)
    // DIAMOND_CLUSTER(CAT_CAT.out.file_out)
    // ch_versions = ch_versions.mix(DIAMOND_CLUSTER.out.versions)
    // realign_ch = CAT_CAT.out.file_out.join(DIAMOND_CLUSTER.out.tsv)
    // DIAMOND_REALIGN(realign_ch)
    // notes to self:
    // incorporate gget
    // incorporate pfam
    // incorporate elm

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

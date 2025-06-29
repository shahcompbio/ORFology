// merge across multiple proteomegenerator results with quant from Fragpipe/Philosopher
process PGTOOLS_MERGERESULTS {
    tag "${meta.id}"
    label 'process_single'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/tcdo_pg_tools:0.0.7b0"
    containerOptions "-v /Volumes/kentsis:/Volumes/kentsis"

    input:
    tuple val(meta), path("samplesheet.csv")
    tuple val(meta)

    output:
    tuple val(meta), path("info_table.tsv"), emit: info_table
    tuple val(meta), path("merged.fasta"), emit: merged_fasta
    tuple val(meta), path("upset_plot.svg"), emit: upset_plot
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def header = """
    tcdo_pg_tools merge-pg-results -i samplesheet.csv --upset
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pgtools: \$(tcdo_pg_tools --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pgtools: \$(pgtools --version)
    END_VERSIONS
    """
}

// sort proteins into categories based on transcript/gene annotation
process CLASSIFYPROTEINS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/tcdo_pg_tools:0.0.7b0"

    input:
    tuple val(meta), path("info_table.tsv")

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.svg"), emit: count_plot
    tuple val(meta), path("*.tsv"), emit: info_table
    tuple val(meta), path("*.csv"), emit: counts_table
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def id_args = meta.id == "merge" ? "protein_ids" : "protein"
    def name_args = meta.id == "merge" ? "protein_name" : "entry_name"
    """
    categorize_proteins.py \\
        info_table.tsv \\
        ${id_args} \\
        ${name_args} \\
        ${meta.id}
    # capture version and write YAML in one go, no standalone ver= line
    ( read -r ver < <(tcdo_pg_tools --version) \
    && printf '%s:\\n  tcdo_pg_tools: \"%s\"\\n' \"${task.process}\" \"\$ver\" \
    ) > versions.yml
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
        classifyproteins: \$(classifyproteins --version)
    END_VERSIONS
    """
}

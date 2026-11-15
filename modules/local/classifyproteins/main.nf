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
    def id_args = meta.id == "merged" ? "protein_ids" : "protein"
    def name_args = meta.id == "merged" ? "protein_name" : "entry_name"
    """
    categorize_proteins.py \\
        info_table.tsv \\
        ${id_args} \\
        ${name_args} \\
        ${prefix}
    # capture version and write YAML in one go, no standalone ver= line
    ( read -r ver < <(tcdo_pg_tools --version) \
    && printf '%s:\\n  tcdo_pg_tools: \"%s\"\\n' \"${task.process}\" \"\$ver\" \
    ) > versions.yml
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_counts_by_category.svg
    touch ${prefix}_counts_by_category.csv
    touch ${prefix}_annotated_info_table.tsv
    # capture version and write YAML in one go, no standalone ver= line
    ( read -r ver < <(tcdo_pg_tools --version) \
    && printf '%s:\\n  tcdo_pg_tools: \"%s\"\\n' \"${task.process}\" \"\$ver\" \
    ) > versions.yml
    """
}

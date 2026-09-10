// convert fasta to tabular format with tcdo_pg_tools
process PGTOOLS_FX2TAB {
    tag "${meta.id}"
    label 'process_single'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/tcdo_pg_tools:0.0.9"

    input:
    tuple val(meta), path(fasta), path(philosopher_quant)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("info_table.tsv"), emit: info_table
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fx2tab.py ${fasta} ${prefix}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(python -c 'import pandas as pd; print(pd.__version__)')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch info_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(python -c 'import pandas as pd; print(pd.__version__)')
    END_VERSIONS
    """
}

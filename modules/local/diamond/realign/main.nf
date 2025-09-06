// get alignments of the cluster members against their representative cluster
process DIAMOND_REALIGN {
    tag "${meta.id}"
    label 'process_medium'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/diamond:2.1.12--hdb4b4cc_1'
        : 'biocontainers/diamond:2.1.12--hdb4b4cc_1'}"

    input:
    tuple val(meta), path("protein.fa"), path("clusters.tsv")

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.aln.tsv"), emit: aln_table
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mem = task.memory.toKilo() + 'K'
    def memarg = "-M ${mem}"
    """
    diamond realign \\
        ${args} \\
        ${memarg} \\
        -p ${task.cpus} \\
        -d protein.fa \\
        --clusters clusters.tsv \\
        -o ${meta.id}.aln.tsv \\
        --header

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        diamond: \$(diamond --version |& sed '1!d ; s/diamond version //')
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
        diamond: \$(diamond --version)
    END_VERSIONS
    """
}

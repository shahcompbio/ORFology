// merge across multiple proteomegenerator results with quant from Fragpipe/Philosopher
process PGTOOLS_MERGERESULTS {
    tag "${meta.id}"
    label 'process_single'

    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "quay.io/shahlab_singularity/tcdo_pg_tools:0.1.0"

    input:
    val meta
    tuple val(meta_list), path(fasta_list, stageAs: "fasta??", arity: "1..*"), path(philosopher_list, stageAs: "quant??", arity: "1..*")

    output:
    tuple val(meta), path("*info_table.tsv"), emit: info_table
    tuple val(meta), path("*.fasta"), emit: merged_fasta
    tuple val(meta), path("*upset_plot.svg"), optional: true, emit: upset_plot
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // build samplesheet from input lists
    def header = "fasta,protein_table,sample,condition"
    def rows = (0..<meta_list.size()).collect { i ->
        def meta1 = meta_list[i]
        def fasta = fasta_list[i]
        def protein_table = meta_list[i].quant != false ? philosopher_list[i] : ''
        "${fasta.name},${protein_table},${meta1.id},${meta1.condition}"
    }
    def csv_lines = ([header] + rows).join("\n")
    // note: escaping newline for bash string
    """
    echo \"${csv_lines}\" > samplesheet.csv

    tcdo_pg_tools \\
    merge-pg-results \\
    -t ${prefix}_info_table.tsv \\
    -fa ${prefix}.fasta \\
    -i samplesheet.csv \\
    ${args}
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
        pgtools: \$(pgtools --version)
    END_VERSIONS
    """
}

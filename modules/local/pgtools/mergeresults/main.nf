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
    upset_path = args.contains('--upset') ? "--upset_path ${prefix}_upset_plot.svg" : ''
    """
    echo \"${csv_lines}\" > samplesheet.csv

    tcdo_pg_tools \\
    merge-pg-results \\
    -t ${prefix}_info_table.tsv \\
    -fa ${prefix}.fasta \\
    -i samplesheet.csv \\
    ${args} \\
    ${upset_path}
    # capture version and write YAML in one go, no standalone ver= line
    ( read -r ver < <(tcdo_pg_tools --version) \
    && printf '%s:\\n  tcdo_pg_tools: \"%s\"\\n' \"${task.process}\" \"\$ver\" \
    ) > versions.yml
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def upset_stub = args.contains('--upset') ? "touch ${prefix}_upset_plot.svg" : ''
    """
    touch ${prefix}_info_table.tsv
    touch ${prefix}.fasta
    ${upset_stub}
    # capture version and write YAML in one go, no standalone ver= line
    ( read -r ver < <(tcdo_pg_tools --version) \
    && printf '%s:\\n  tcdo_pg_tools: \"%s\"\\n' \"${task.process}\" \"\$ver\" \
    ) > versions.yml
    """
}

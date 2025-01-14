process DIANNCONVERT {
    tag "$meta.experiment_id"
    label 'process_medium'

    conda "conda-forge::pandas_schema conda-forge::lzstring bioconda::pmultiqc=0.0.25"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pmultiqc:0.0.25--pyhdfd78af_0' :
        'biocontainers/pmultiqc:0.0.25--pyhdfd78af_0' }"


    input:
    path(report)
    path(exp_design)
    path(report_pg)
    path(report_pr)
    path(ms_information)
    val(meta)
    path(fasta)
    path("version/versions.yml")

    output:
    path "*msstats_in.csv", emit: out_msstats
    path "*triqler_in.tsv", emit: out_triqler
    path "*.mzTab", emit: out_mztab
    path "*.log", emit: log
    path "versions.yml", emit: version

    exec:
        log.info "DIANNCONVERT is based on the output of DIA-NN 1.8.1 and 1.9.beta.1, other versions of DIA-NN do not support mzTab conversion."

    script:
    def args = task.ext.args ?: ''
    def dia_params = [meta.fragmentmasstolerance,meta.fragmentmasstoleranceunit,meta.precursormasstolerance,
                        meta.precursormasstoleranceunit,meta.enzyme,meta.fixedmodifications,meta.variablemodifications].join(';')

    """
    diann_convert.py convert \\
        --folder ./ \\
        --exp_design ${exp_design} \\
        --diann_version ./version/versions.yml \\
        --dia_params "${dia_params}" \\
        --charge $params.max_precursor_charge \\
        --missed_cleavages $params.allowed_missed_cleavages \\
        --qvalue_threshold $params.protein_level_fdr_cutoff \\
        2>&1 | tee convert_report.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyopenms: \$(pip show pyopenms | grep "Version" | awk -F ': ' '{print \$2}')
    END_VERSIONS
    """
}

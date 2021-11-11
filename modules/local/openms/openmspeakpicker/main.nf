// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process OPENMSPEAKPICKER {
    label 'process_low'
    publishDir "${params.outdir}/logs",
        mode: params.publish_dir_mode,
        pattern: "*.log",
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "openms::openms-thirdparty=2.7.0pre" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/openms:2.6.0--h4afb90d_0"
    } else {
        container "quay.io/biocontainers/openms:2.6.0--h4afb90d_0"
    }

    input:
    tuple val(mzml_id), path(mzml_file)

    output:
    tuple val(mzml_id), path("*.mzML"), emit: mzmls_picked
    path "*.version.txt", emit: version
    path "*.log", emit: log

    script:
    def software = getSoftwareName(task.process)
    in_mem = params.peakpicking_inmemory ? "inmermory" : "lowmemory"
    lvls = params.peakpicking_ms_levels ? "-algorithm:ms_levels ${params.peakpicking_ms_levels}" : ""

    """
    PeakPickerHiRes \\
        -in ${mzml_file} \\
        -out ${mzml_file.baseName}.mzML \\
        -threads $task.cpus \\
        -debug $params.pp_debug \\
        -processOption ${in_mem} \\
        ${lvls} \\
        $options.args \\
        > ${mzml_file.baseName}_pp.log

    echo \$(PeakPickerHiRes --version 2>&1) > ${software}.version.txt
    """
}

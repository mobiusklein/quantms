// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process OPENMSPEAKPICKER {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}/logs",
        mode: params.publish_dir_mode,
        pattern: "*.log",
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? "bioconda::bumbershoot bioconda::comet-ms bioconda::crux-toolkit=3.2 bioconda::fido=1.0 conda-forge::gnuplot bioconda::luciphor2=2020_04_03 bioconda::msgf_plus=2021.03.22 openms::openms=2.7.0pre bioconda::pepnovo=20101117 bioconda::percolator=3.5 bioconda::sirius-csifingerid=4.0.1 bioconda::thermorawfileparser=1.3.4 bioconda::xtandem=15.12.15.2 bioconda::openms-thirdparty=2.7.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/openms-thirdparty:2.7.0--h9ee0642_1"
    } else {
        container "quay.io/biocontainers/openms-thirdparty:2.7.0--h9ee0642_1"
    }

    input:
    tuple val(meta), path(mzml_file)

    output:
    tuple val(meta), path("*.mzML"), emit: mzmls_picked
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

    echo \$(PeakPickerHiRes 2>&1) > ${software}.version.txt
    """
}

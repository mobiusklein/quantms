//
// search engines msgf,comet and index peptide
//

params.msgf_options = [:]
params.comet_options = [:]
params.indexpeptides_options = [:]

include { SEARCHENGINEMSGF } from '../../modules/local/openms/thirdparty/searchenginemsgf/main' addParams( options: params.msgf_options )
include { SEARCHENGINECOMET} from '../../modules/local/openms/thirdparty/searchenginecomet/main' addParams( options: params.comet_options )
include { INDEXPEPTIDES } from '../../modules/local/openms/indexpeptides/main' addParams( options: params.indexpeptides_options)

workflow DATABASESEARCHENGINES {
    take:
    mzmls_search
    searchengine_in_db
    searchengine_setting
    idx_settings

    main:
    (ch_id_msgf, ch_id_comet, ch_versions) = [ Channel.empty(), Channel.empty(), Channel.empty() ]

    if (params.search_engines.contains("msgf")){
        SEARCHENGINEMSGF(searchengine_setting.join(mzmls_search).combine(searchengine_in_db))
        ch_versions = ch_versions.mix(SEARCHENGINEMSGF.out.version)
        ch_id_msgf = ch_id_msgf.mix(SEARCHENGINEMSGF.out.id_files_msgf)
    }

    if (params.search_engines.contains("comet")){
        SEARCHENGINECOMET(searchengine_setting.join(mzmls_search).combine(searchengine_in_db))
        ch_versions = ch_versions.mix(SEARCHENGINECOMET.out.version)
        ch_id_comet = ch_id_comet.mix(SEARCHENGINECOMET.out.id_files_comet)
    }

    INDEXPEPTIDES(ch_id_msgf.mix(ch_id_comet).combine(idx_settings, by: 0), searchengine_in_db)

    emit:
    ch_id_files_idx = INDEXPEPTIDES.out.id_files_idx

    versions        = ch_versions
}

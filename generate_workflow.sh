wget http://code.pycbc.phy.syr.edu/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_make_coinc_search_workflow
wget http://code.pycbc.phy.syr.edu/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_submit_dax
chmod +x pycbc_make_coinc_search_workflow pycbc_submit_dax

WORKFLOW_NAME=gw150914-16day-c01-v1.3.2
OUTPUT_PATH=${HOME}/public_html/gw150914/${WORKFLOW_NAME}
./pycbc_make_coinc_search_workflow --workflow-name \
      ${WORKFLOW_NAME} --output-dir output --config-files \
      https://code.pycbc.phy.syr.edu/ligo-cbc/pycbc-config/download/4a82467e48b811866b7cee07dd37bd147119856e/O1/pipeline/analysis.ini \
      https://code.pycbc.phy.syr.edu/ligo-cbc/pycbc-config/download/a227ac6d4accdf5d9b4e51b93cc92543fe7e1ebc/O1/pipeline/plotting.ini \
      https://code.pycbc.phy.syr.edu/ligo-cbc/pycbc-config/download/541d4dc77d4d0fbc1b622ed0af4ef17f02fca685/ER8/pipeline/data_C01.ini \
      https://code.pycbc.phy.syr.edu/ligo-cbc/pycbc-config/download/541d4dc77d4d0fbc1b622ed0af4ef17f02fca685/ER8/pipeline/gps_times_ER8B_analysis_16day_C01.ini \
      https://code.pycbc.phy.syr.edu/ligo-cbc/pycbc-software/download/master/v1.3.2/x86_64/composer_xe_2015.0.090/executables.ini \
      --config-overrides \
      "results_page:output-path:${OUTPUT_PATH}" \
      "coinc-full:timeslide-interval:0.1" \
      "workflow-coincidence:background-bins:bns:chirp:1.74 edge:SEOBNRv2Peak:220 bulk:total:150" \
      "inspiral:cluster-window:4" \
      "inspiral:chisq-bins:\"0.4*get_freq('fSEOBNRv2Peak',params.mass1,params.mass2,params.spin1z,params.spin2z)**(2./3.)\"" \
      "coinc-full:decimation-factor:100" \
      "page_ifar:decimation-factor:10000" \
      "coinc-full:loudest-keep:5000" \
      "pegasus_profile-distribute_background_bins:condor|request_memory:200000" \
      "pegasus_profile-statmap:condor|request_memory:200000"

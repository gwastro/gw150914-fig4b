#!/bin/bash -v

git clean -dxf

virtualenv pycbc-v1.13.0
source pycbc-v1.13.0/bin/activate
pip install --upgrade pip setuptools
pip install -r https://raw.githubusercontent.com/gwastro/pycbc/v1.13.0/requirements.txt
pip install 'pycbc==1.13.0'
pip install 'lalsuite==6.48.1.dev20180717'
deactivate
export PYCBC_1_13_0_PATH=${PWD}/pycbc-v1.13.0

cat > ${PYCBC_1_13_0_PATH}/bin/pycbc_losc_segment_query.sh << EOF
#!/bin/bash

unset LD_LIBRARY_PATH
unset PYTHONPATH

source ${PYCBC_1_13_0_PATH}/bin/activate

echo "Calling ${PYCBC_1_13_0_PATH}/bin/pycbc_losc_segment_query \${@}"

${PYCBC_1_13_0_PATH}/bin/pycbc_losc_segment_query \${@}

exit \$?
EOF
chmod +x ${PYCBC_1_13_0_PATH}/bin/pycbc_losc_segment_query.sh

wget https://git.ligo.org/ligo-cbc/pycbc-software/raw/master/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_make_coinc_search_workflow
wget https://git.ligo.org/ligo-cbc/pycbc-software/raw/master/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_submit_dax
chmod +x pycbc_make_coinc_search_workflow pycbc_submit_dax

wget https://git.ligo.org/ligo-cbc/pycbc-software/raw/efd37637fbb568936dfb92bc7aa8a77359c9aa36/v1.3.2/x86_64/composer_xe_2015.0.090/executables.ini
perl -pi.bak -e 's+http://code.pycbc.phy.syr.edu/pycbc-software/+https://git.ligo.org/ligo-cbc/pycbc-software/raw/master/+g' executables.ini

WORKFLOW_NAME=gw150914-16day-c01-v1.3.2
OUTPUT_PATH=${HOME}/secure_html/gw150914/${WORKFLOW_NAME}
./pycbc_make_coinc_search_workflow --workflow-name \
      ${WORKFLOW_NAME} --output-dir output --config-files \
      https://raw.githubusercontent.com/gwastro/pycbc-config/4a82467e48b811866b7cee07dd37bd147119856e/O1/pipeline/analysis.ini \
      https://raw.githubusercontent.com/gwastro/pycbc-config/a227ac6d4accdf5d9b4e51b93cc92543fe7e1ebc/O1/pipeline/plotting.ini \
      https://raw.githubusercontent.com/gwastro/pycbc-config/541d4dc77d4d0fbc1b622ed0af4ef17f02fca685/ER8/pipeline/data_C01.ini \
      https://raw.githubusercontent.com/gwastro/pycbc-config/541d4dc77d4d0fbc1b622ed0af4ef17f02fca685/ER8/pipeline/gps_times_ER8B_analysis_16day_C01.ini \
      executables.ini \
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
      "pegasus_profile-statmap:condor|request_memory:200000" \
      "executables:segment_query:${PYCBC_1_13_0_PATH}/bin/pycbc_losc_segment_query.sh" \
      "workflow:h1-channel-name:H1:GWOSC-16KHZ_R1_STRAIN" \
      "workflow:l1-channel-name:L1:GWOSC-16KHZ_R1_STRAIN" \
      "workflow-datafind:datafind-h1-frame-type:H1_LOSC_16_V1" \
      "workflow-datafind:datafind-l1-frame-type:L1_LOSC_16_V1" \
      "workflow-segments:segments-h1-science-name:H1:RESULT:1" \
      "workflow-segments:segments-l1-science-name:L1:RESULT:1" \
      "workflow-segments:segments-database-url:https://losc.ligo.org/archive/O1" \
      "workflow-segments:segments-generate-segment-files:if_not_present" \
      "workflow-segments:segments-science-veto:1" \
      "workflow-segments:segments-final-veto-group:12H" \
      "workflow-segments:segments-veto-definer-url:https://raw.githubusercontent.com/gwastro/1-ogc/master/workflow/auxiliary_files/H1L1-DUMMY_O1_CBC_VDEF-1126051217-1220400.xml" \
      "datafind:urltype:file" \
      "workflow-tmpltbank:tmpltbank-pregenerated-bank:https://github.com/gwastro/pycbc-config/raw/41676894561059629eb5715673d7e6dea7a76865/ER8/bank/H1L1-UBERBANK_MAXM100_NS0p05_ER8HMPSD-1126033217-223200.xml.gz" \
      "workflow-gating:gating-pregenerated-file-h1:https://github.com/gwastro/pycbc-config/raw/1e9aee13ebf85e916136afc4a9ae57f5b2d5bc64/O1/dq/H1-gating_C01_SNR300-1126051217-1129383017.txt.gz" \
      "workflow-gating:gating-pregenerated-file-l1:https://github.com/gwastro/pycbc-config/raw/1e9aee13ebf85e916136afc4a9ae57f5b2d5bc64/O1/dq/L1-gating_C01_SNR300-1126051217-1129383017.txt.gz" \
      'results_page:analysis-title:"PyCBC GW150914 Search Result LOSC Data"'


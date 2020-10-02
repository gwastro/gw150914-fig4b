#! /bin/bash -v

set -e

# comment if you DON'T want inspiral jobs to run on OSG
INSPIRAL_ON_OSG=True

# set the path to the templated pegasus site catalog file to use
export TOP_DIR=${PWD}
export PEGASUS_SITE_CATALOG_PATH=`pwd`/catalogs
export SUBMIT_HOSTNAME=`hostname -f`

if [ "X$SUBMIT_HOSTNAME" = "X" ]; then
    echo "Unable to determine hostname for the submit host"
    exit 1
fi

if [ ! -z "$INSPIRAL_ON_OSG" ]; then
    if [ "X$OSG_PROJECT_NAME" = "X" ]; then
	echo "Please set env variable OSG_PROJECT_NAME to the project to which your jobs will be charged to"
	exit 1
    fi
    echo "The workflows will use SCP endpoint at $SUBMIT_HOSTNAME to transfer workflows intermediate data and outputs to/from OSG"
fi


git clean -dxf

virtualenv pycbc-v1.13.2
source pycbc-v1.13.2/bin/activate
pip install --upgrade pip setuptools==44.1.0 
pip install lscsoft-glue==1.60.0
pip install -r https://raw.githubusercontent.com/gwastro/pycbc/v1.13.2/requirements.txt
pip install 'pycbc==1.13.2'
pip install 'lalsuite==6.48.1.dev20180717'
deactivate
export PYCBC_1_13_2_PATH=${PWD}/pycbc-v1.13.2

cat > ${PYCBC_1_13_2_PATH}/bin/pycbc_losc_segment_query.sh << EOF
#!/bin/bash

unset LD_LIBRARY_PATH
unset PYTHONPATH

source ${PYCBC_1_13_2_PATH}/bin/activate

echo "Calling ${PYCBC_1_13_2_PATH}/bin/pycbc_losc_segment_query \${@}"

${PYCBC_1_13_2_PATH}/bin/pycbc_losc_segment_query --protract-hw-inj 8 \${@}

exit \$?
EOF
chmod +x ${PYCBC_1_13_2_PATH}/bin/pycbc_losc_segment_query.sh

curl -L https://pegasus.isi.edu/ligo/eager/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_foreground_minifollowup > pycbc_foreground_minifollowup_v1.3.2
curl -L https://pegasus.isi.edu/ligo/eager/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_injection_minifollowup > pycbc_injection_minifollowup_1.3.2
curl -L https://pegasus.isi.edu/ligo/eager/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_sngl_minifollowup > pycbc_sngl_minifollowup_1.3.2
chmod +x pycbc_foreground_minifollowup_v1.3.2 pycbc_injection_minifollowup_1.3.2 pycbc_sngl_minifollowup_1.3.2

cat > minifollowup_wrapper.sh << EOF
#!/bin/bash
set -e

OPTS=\${@}

while (( "\${#}" )) ; do
  case "\$1" in
    --output-map ) MAPFILE="\$2"; shift 2 ;;
    --output-file ) DAXFILE="\$2"; shift 2 ;;
    --version ) echo "minifollowup_wrapper.sh running v1.3.2"; exit 0;;
    * ) shift;;
  esac
done

if [[ "\${0}" == *"foreground_minifollowup"* ]]; then
  PROGRAM=${PWD}/pycbc_foreground_minifollowup_v1.3.2
elif [[ "\${0}" == *"injection_minifollowup"* ]]; then
  PROGRAM=${PWD}/pycbc_injection_minifollowup_1.3.2
elif [[ "\${0}" == *"singles_minifollowup"* ]]; then
  PROGRAM=${PWD}/pycbc_sngl_minifollowup_1.3.2
else
  echo "Error: unable to determine program to use, called with \${0}"
  exit 1
fi

echo
echo "====================================================================="
echo
echo "minifollowup running \${PROGRAM} with arguments \${OPTS}"
echo

\${PROGRAM} \${OPTS}

echo
echo "====================================================================="
echo

if [ ! -z "\${MAPFILE}" ] ; then
  echo "minifollowup fixing \${MAPFILE}"
  perl -pi.bak -e 's+ /+ file:///+' \${MAPFILE}
fi

if [ ! -z "\${DAXFILE}" ] ; then
  echo "minifollowup fixing \${DAXFILE}"
  perl -pi.bak -e  "s+url=\"([HL])+url=\"file://\${PWD}/\\\$1+g" \${DAXFILE}
fi

exit \$?
EOF
chmod +x minifollowup_wrapper.sh

wget https://pegasus.isi.edu/ligo/eager/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_make_coinc_search_workflow
wget https://pegasus.isi.edu/ligo/eager/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/pycbc_submit_dax
chmod +x pycbc_make_coinc_search_workflow pycbc_submit_dax

wget https://pegasus.isi.edu/ligo/eager/pycbc-software/v1.3.2/x86_64/composer_xe_2015.0.090/executables.ini
perl -pi.bak -e 's+http://code.pycbc.phy.syr.edu/pycbc-software/+https://pegasus.isi.edu/ligo/eager/pycbc-software/+g' executables.ini

export LIGO_DATAFIND_SERVER=sugwg-condor.phy.syr.edu:80
export LAL_DATA_PATH="/cvmfs/oasis.opensciencegrid.org/ligo/sw/pycbc/lalsuite-extra/8/share/lalsimulation"

WORKFLOW_NAME=gw150914-16day-c01-v1.3.2
OUTPUT_PATH=${HOME}/secure_html/gw150914/${WORKFLOW_NAME}
ADDON_ARGS=""

if [ ! -z "$INSPIRAL_ON_OSG" ]; then
    # set profile for inspiral jobs to always run on OSG
    ADDON_ARGS="pegasus_profile-inspiral:hints|execution.site:osg" 
fi

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
      "pegasus_profile-combine_statmap:condor|request_memory:200000" \
      "pegasus_profile-plot_snrifar:condor|request_memory:200000" \
      "pegasus_profile-distribute_background_bins:condor|+WantsGigantor:True" \
      "pegasus_profile-statmap:condor|+WantsGigantor:True" \
      "pegasus_profile-combine_statmap:condor|+WantsGigantor:True" \
      "pegasus_profile-plot_snrifar:condor|+WantsGigantor:True" \
      "pegasus_profile-plot_trigger_timeseries:condor|request_memory:16000" \
      "pegasus_profile-page_snglinfo:condor|request_memory:16000" \
      "pegasus_profile-plot_singles_timefreq:condor|request_memory:16000" \
      "executables:foreground_minifollowup:${PWD}/minifollowup_wrapper.sh" \
      "executables:injection_minifollowup:${PWD}/minifollowup_wrapper.sh" \
      "executables:singles_minifollowup:${PWD}/minifollowup_wrapper.sh" \
      "executables:segment_query:${PYCBC_1_13_2_PATH}/bin/pycbc_losc_segment_query.sh" \
      "workflow:h1-channel-name:H1:GWOSC-16KHZ_R1_STRAIN" \
      "workflow:l1-channel-name:L1:GWOSC-16KHZ_R1_STRAIN" \
      "workflow-datafind:datafind-h1-frame-type:H1_LOSC_16_V1" \
      "workflow-datafind:datafind-l1-frame-type:L1_LOSC_16_V1" \
      "workflow-segments:segments-h1-science-name:H1:RESULT:1" \
      "workflow-segments:segments-l1-science-name:L1:RESULT:1" \
      "workflow-segments:segments-database-url:https://losc.ligo.org/archive/O1" \
      "workflow-segments:segments-generate-segment-files:if_not_present" \
      "executables:segments_from_cats:file:///bin/true" \
      "workflow-segments:segments-science-veto:1" \
      "workflow-segments:segments-final-veto-group:12H" \
      "workflow-segments:segments-veto-definer-url:https://raw.githubusercontent.com/gwastro/1-ogc/master/workflow/auxiliary_files/H1L1-DUMMY_O1_CBC_VDEF-1126051217-1220400.xml" \
      "datafind:urltype:file" \
      "workflow-tmpltbank:tmpltbank-pregenerated-bank:https://github.com/gwastro/pycbc-config/raw/41676894561059629eb5715673d7e6dea7a76865/ER8/bank/H1L1-UBERBANK_MAXM100_NS0p05_ER8HMPSD-1126033217-223200.xml.gz" \
      "workflow-gating:gating-pregenerated-file-h1:https://github.com/gwastro/pycbc-config/raw/1e9aee13ebf85e916136afc4a9ae57f5b2d5bc64/O1/dq/H1-gating_C01_SNR300-1126051217-1129383017.txt.gz" \
      "workflow-gating:gating-pregenerated-file-l1:https://github.com/gwastro/pycbc-config/raw/1e9aee13ebf85e916136afc4a9ae57f5b2d5bc64/O1/dq/L1-gating_C01_SNR300-1126051217-1129383017.txt.gz" \
      'results_page:analysis-title:"PyCBC GW150914 Search Result LOSC Data"' \
      $ADDON_ARGS

pushd output

# Fix the paths to the output map files in the dax
perl -pi.bak -e "s+Dpegasus.dir.storage.mapper.replica.file=([HL])+Dpegasus.dir.storage.mapper.replica.file=${PWD}/local-site-scratch/work/00/00/main_ID0000001/\$1+g" main.dax

PLANNER_ARGS=""
if [ ! -z "$INSPIRAL_ON_OSG" ]; then
      # update the gwf files to be on site osg in addition to local
      # <pfn url="file:///cvmfs/gwosc.osgstorage.org/gwdata/O1/strain.16k/frame.v1/H1/1128267776/H-H1_LOSC_16_V1-1128333312-4096.gwf" site="local"/>
      echo "Updating site attribute of gwf files to be also on OSG"
      perl -0 -pi.bak -e 's+(<pfn url="file:///cvmfs/gwosc.osgstorage.org/gwdata/O1/strain.16k/frame.v1/.*?gwf") (site="local"/>)+$1 $2 \n\t$1 site="osg"/>+gms' main.dax

      # pass additional arguments to pycbc_submit_dax
      # set bypass input file staging to true
      # execution sites both local and OSG, with staging site set for OSG to be local site
      PLANNER_ARGS="-P pegasus.transfer.bypass.input.staging=true -s osg -S osg=local"

      # update the dax arguments for main.dax to have --staging-site osg=local
      perl -0 -pi.bak -e 's+(<dax id="ID0000001" file="main.dax">.*?)</argument>+$1 --staging-site osg=local</argument>+gms' gw150914-16day-c01-v1.3.2.dax 

fi

../pycbc_submit_dax --force-no-accounting-group --dax gw150914-16day-c01-v1.3.2.dax -P pegasus.integrity.checking=nosymlink  --no-create-proxy $PLANNER_ARGS

popd

exit 0

#!/bin/bash -v

if [ ! -z ${VIRTUAL_ENV} ] ; then
  deactivate
  fi

source /home/dbrown/src/pycbc-1.3.4/bin/activate

./pycbc_dogsin_hist_sigmas_arrow --exclusive-bkg --trigger-file ./gw150914-16day-c01-v1.3.2/H1L1-STATMAP_FULL_DATA_FULL_CUMULATIVE_CAT_12H_FULL_DATA_FULL_BIN_1-1126051217-3331800.hdf --x-min 7.85 --x-max 25.2 --y-min 1e-8 --y-max 200 --trials-factor 3 --output-file pycbc-hist-0p1s-sigmas-arrow.pdf --bin-size 0.2

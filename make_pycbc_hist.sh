#!/bin/bash -v

set -e

# back up any existing python local directory

PYTHON_LOCAL=$(mktemp --tmpdir=${PWD} local.XXXXXXXXXX)
rm ${PYTHON_LOCAL}

if [ -d ${HOME}/.local ] ; then
  mv ${HOME}/.local ${PYTHON_LOCAL}
fi

# install pip and virtualenv following instructions from
# https://github.com/gwastro/pycbc/blob/v1.3.4/docs/install_virtualenv.rst

rm -rf ${PWD}/local

VERSION=`python -c 'import sys; print "%d.%d" % (sys.version_info[0], sys.version_info[1])'`
mkdir -p ${PWD}/local/pip-7.1.0/lib/python${VERSION}/site-packages
export PYTHONPATH=${PWD}/local/pip-7.1.0/lib/python${VERSION}/site-packages
export PATH=${PWD}/local/pip-7.1.0/bin:${PATH}

easy_install --prefix=${PWD}/local/pip-7.1.0 https://pypi.python.org/packages/source/p/pip/pip-7.1.0.tar.gz#md5=d935ee9146074b1d3f26c5f0acfd120e

mkdir -p ${HOME}/.local/bin
export PATH=${HOME}/.local/bin:${PATH}
pip install --user 'virtualenv==13.1.1'

# create a pycbc virtual environment
NAME=pycbc-v1.3.4
unset PYTHONPATH
unset LD_LIBRARY_PATH
rm -rf $NAME
virtualenv $NAME

source $NAME/bin/activate
mkdir -p $VIRTUAL_ENV/src

# install minimal set of dependencies to make the plot based on the code in
# the pycbc install script
#   https://github.com/gwastro/pycbc/blob/v1.3.4/install_pycbc.sh
# the dependencies in
#   https://github.com/gwastro/pycbc/blob/v1.3.4/setup.py
# and
#   https://github.com/gwastro/pycbc/blob/v1.3.4/requirements.txt
pip install 'numpy==1.9.3'
pip install 'scipy==0.13.0'
pip install 'unittest2==1.1.0'
pip install 'Cython==0.23.2'
pip install 'python-cjson==1.1.0' 
pip install 'matplotlib==1.5.1' 
pip install 'Pillow==2.9.0'
pip install 'pyRXP==2.1.0'

pushd $VIRTUAL_ENV/src
curl -L https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.12/src/hdf5-1.8.12.tar.gz > hdf5-1.8.12.tar.gz
tar -zxvf hdf5-1.8.12.tar.gz
rm hdf5-1.8.12.tar.gz
pushd hdf5-1.8.12
./configure --prefix=$VIRTUAL_ENV/opt/hdf5-1.8.12
make -j install
HDF5_DIR=${VIRTUAL_ENV}/opt/hdf5-1.8.12 pip $cache install 'h5py==2.5.0'
popd
popd

# building lalsuite requires swig >= 2.0.11
curl -L https://sourceforge.net/projects/swig/files/swig/swig-2.0.11/swig-2.0.11.tar.gz/download > swig-2.0.11.tar.gz
rm -rf swig-2.0.11
tar -zxvf swig-2.0.11.tar.gz
pushd swig-2.0.11
./configure --prefix=${VIRTUAL_ENV}/opt/swig-2.0.11
make
make install
export PATH=${VIRTUAL_ENV}/opt/swig-2.0.11/bin:${PATH}
popd

curl -L http://software.igwn.org/lscsoft/source/metaio-8.4.0.tar.gz > metaio-8.4.0.tar.gz
rm -rf metaio-8.4.0
tar -zxvf metaio-8.4.0.tar.gz
pushd metaio-8.4.0
CPPFLAGS=-std=gnu99 ./configure --prefix=${VIRTUAL_ENV}/opt/metaio-8.4.0
make
make install
popd

curl -L http://software.igwn.org/lscsoft/source/libframe-8.30.tar.gz > libframe-8.30.tar.gz
rm -rf libframe-8.30
tar -zxvf libframe-8.30.tar.gz
pushd libframe-8.30
./configure --prefix=${VIRTUAL_ENV}/opt/libframe-8.30
make
make install
popd

# install lalsuite v6.36
rm -rf lalsuite-archive
git clone https://github.com/lscsoft/lalsuite-archive.git
pushd lalsuite-archive
git checkout lalsuite-v6.36
./00boot
LDFLAGS="-L${VIRTUAL_ENV}/opt/metaio-8.4.0/lib -L${VIRTUAL_ENV}/opt/libframe-8.30/lib" CPPFLAGS="-I${VIRTUAL_ENV}/opt/metaio-8.4.0/include -I${VIRTUAL_ENV}/opt/libframe-8.30/include" ./configure --prefix=${VIRTUAL_ENV}/opt/lalsuite --enable-swig-python --disable-lalstochastic --disable-lalxml --disable-lalinference --disable-laldetchar
make -j
make install
popd

echo 'source ${VIRTUAL_ENV}/opt/lalsuite/etc/lalsuiterc' >> ${VIRTUAL_ENV}/bin/activate
source ${VIRTUAL_ENV}/opt/lalsuite/etc/lalsuiterc

# install glue and pylal
pip install 'pycbc-glue==0.9.6' 'pycbc-pylal==0.9.5'

# install v1.3.4
reltag=v1.3.4
pip install git+https://github.com/ligo-cbc/pycbc@${reltag}#egg=pycbc

# run the plotting code
./pycbc_dogsin_hist_sigmas_arrow --exclusive-bkg --trigger-file ./output/full_data/H1L1-STATMAP_FULL_DATA_FULL_CUMULATIVE_CAT_12H_FULL_DATA_FULL_BIN_1-1126051217-3331800.hdf --x-min 7.85 --x-max 25.2 --y-min 1e-8 --y-max 200 --trials-factor 3 --output-file pycbc-hist-0p1s-sigmas-arrow.pdf --bin-size 0.2

# leave the virtual environment
deactivate

# restore the python local directory
if [ -d ${PYTHON_LOCAL} ] ; then
  rm -rf ${HOME}/.local
  mv ${PYTHON_LOCAL} ${HOME}/.local
fi

exit 0

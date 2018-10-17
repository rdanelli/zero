#!/bin/bash
. .config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

pushd ${OUT}
cd ${OUT}

echo resume: mvn $1 -rf \:$2 | tee ${LOG} 2>${ERR}
mvn $1 -rf \:$2 | tee ${LOG} 2>${ERR}

popd


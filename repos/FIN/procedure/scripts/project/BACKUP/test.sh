#!/bin/bash
. .config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

[ $# -eq 1 ] && TARGETENV=${1}

pushd ${OUT}
cd ${OUT}

echo compilazione: mvn --offline clean install p:assemble-dist -Dcouchbase -DtargetEnv=${TARGETENV} | tee ${LOG} 2>${ERR}
#mvn --offline clean install p:assemble-dist -Dcouchbase -DtargetEnv=${TARGETENV} | tee ${LOG} 2>${ERR}

#STATUS=${?}

popd
#exit ${STATUS}

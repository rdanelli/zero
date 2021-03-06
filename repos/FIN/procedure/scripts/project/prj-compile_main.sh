#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`

[ $# -eq 1 ] && TARGETENV=${1} 

[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${TARGETENV}_${DATA}.log
#ERR=${PWD}/${LDIR}/${FNAME}_${TARGETENV}_${DATA}.err


pushd ${OUT}

cd ${OUT}

echo "Compilazione main project: mvn -U -DskipTests -Dmaven.test.skip=true p:clean clean install" | tee ${LOG} 2>&1
${MVN} -U -DskipTests -Dmaven.test.skip=true p:clean clean install | tee -a ${LOG} 2>&1
STATUS=${?}

popd
exit ${STATUS}

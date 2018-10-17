#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`

[ $# -eq 1 ] && TARGETENV=${1} 

[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${TARGETENV}_${DATA}.log
#ERR=${PWD}/${LDIR}/${FNAME}_${TARGETENV}_${DATA}.err

cd ${OUT2}

echo "mvn -DskipTests -Dmaven.test.skip=true p:clean clean install p:assemble-dist -DtargetEnv=${TARGETENV}"  | tee -a ${LOG} 2>&1
${MVN} -DskipTests -Dmaven.test.skip=true p:clean clean install p:assemble-dist -DtargetEnv=${TARGETENV}  | tee -a ${LOG} 2>&1

STATUS=${?}

exit ${STATUS}

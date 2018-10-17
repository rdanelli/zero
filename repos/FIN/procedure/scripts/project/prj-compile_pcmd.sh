#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`

[ $# -eq 1 ] && TARGETENV=${1} 

[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${TARGETENV}_${DATA}.log
#ERR=${PWD}/${LDIR}/${FNAME}_${TARGETENV}_${DATA}.err

cd ${OUT}/migration-client

echo "mvn -DskipTests -Dmaven.test.skip=true p:clean clean install -DtargetEnv=${TARGETENV}"  | tee -a ${LOG} 2>&1
${MVN} -U -DskipTests -Dmaven.test.skip=true p:clean clean install -DtargetEnv=${TARGETENV}  | tee -a ${LOG} 2>&1

REVISION=$"`svn info /opt/svn/gele_finegil_10-16 | grep Revision\:`"
echo REVISION .${REVISION}.
echo ${REVISION} > target/pcmd/version.txt

STATUS=${?}

exit ${STATUS}

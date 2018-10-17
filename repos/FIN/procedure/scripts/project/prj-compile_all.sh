#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

[ $# -eq 1 ] && TARGETENV=${1} 

pushd ${OUT}
cd ${OUT}

#echo compilazione: mvn clean install p:assemble-dist -Dcouchbase -DtargetEnv=${TARGETENV} | tee ${LOG} 2>${ERR}
#mvn clean install p:assemble-dist -Dcouchbase -DtargetEnv=${TARGETENV} | tee -a ${LOG} 2>${ERR}

cd ${OUT}

echo "Compilazione main project: mvn -U -DskipTests -Dmaven.test.skip=true p:clean clean install" | tee ${LOG} 2>${ERR}
${MVN}  -U -DskipTests -Dmaven.test.skip=true p:clean clean install | tee -a ${LOG} 2>${ERR}
STATUS1=${?}

cd ${OUT2}
echo "mvn -DskipTests -Dmaven.test.skip=true p:clean clean install p:assemble-dist -DtargetEnv=${TARGETENV}"  | tee -a ${LOG} 2>${ERR}
${MVN} -DskipTests -Dmaven.test.skip=true p:clean clean install p:assemble-dist -DtargetEnv=${TARGETENV}  | tee -a ${LOG} 2>${ERR}

STATUS2=${?}

STATUS=$((STATUS1+STATUS2))

popd
exit ${STATUS}

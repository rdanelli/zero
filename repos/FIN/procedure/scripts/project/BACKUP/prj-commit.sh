#!/bin/bash
. .config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

echo ${FNAME}..${LOG}..${ERR} > ${LOG} 2>${ERR}

exit 0

#pushd ${OUT} && svn --username ${USE} --password ${UPW} co ${SVNBASE}/${PRJ} ${OUT} && popd
#svn --username ${USE} --password ${UPW} up ${OUT}

pushd ${OUT}
cd ${OUT}

echo assemble-dist: mvn p:assemble-dist -Dcouchbase -DtargetEnv=test | tee ${LOG} 2>${ERR}
mvn p:assemble-dist -Dcouchbase -DtargetEnv=test | tee ${LOG} 2>${ERR}

popd


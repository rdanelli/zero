#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

ls -l ${NEWDIST} | tee ${LOG} 2>${ERR}

[ -d ${DEST} ] && mv ${DEST} ${DESTBK} | tee -a ${LOG} 2>${ERR} && mv ${NEWDIST} ${DEST} | tee -a ${LOG} 2>${ERR}

STATUS=${?}

ls -l ${DEST} | tee -a ${LOG} 2>${ERR}

exit ${STATUS}

#!/bin/bash

##[ -e ${CFG} ] && . ${CFG} || . .config
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

echo "AGGIORNAMENTO del codice del progetto" | tee ${LOG} 2>&1
echo svn up ${OUT} | tee -a ${LOG} 2>${ERR}
svn --username ${USE} --password ${UPW} up ${OUT} | tee -a ${LOG} 2>${ERR}

exit ${?}

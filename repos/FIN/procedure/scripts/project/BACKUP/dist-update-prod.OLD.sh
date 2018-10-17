#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

echo "AGGIORNAMENTO della distribuzione su server di produzione" | tee ${LOG} 2>${ERR}

echo "Nuova dist in ${NEWDIST}" | tee -a ${LOG} 2>${ERR}
ls -l ${NEWDIST} | tee -a ${LOG} 2>${ERR}

#echo "verifica presenza cartella ${DEST} su prod " | tee -a ${LOG} 2>${ERR}
#ssh -i ${SEC} poly-bend3 "ls -l ${DEST}" | tee -a ${LOG} 2>${ERR}

echo "RINOMINO la cartella ${DEST} in ${DESTBK} su prod" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 "mv ${DEST} ${DESTBK}" | tee -a ${LOG} 2>${ERR}

echo "COPIO la nuova distribuzione compilata su prod" | tee -a ${LOG} 2>${ERR}
scp -i ${SEC} -pr ${NEWDIST} poly-bend3:${DEST} | tee -a ${LOG} 2>${ERR}

exit 0 


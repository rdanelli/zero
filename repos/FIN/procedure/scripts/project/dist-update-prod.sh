#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

DST=jboss16.prod.fin

echo "AGGIORNAMENTO della distribuzione su server di prod" | tee ${LOG} 2>${ERR}

echo "Nuova dist in ${NEWDIST}" | tee -a ${LOG} 2>${ERR}
ls -l ${NEWDIST} | tee -a ${LOG} 2>${ERR}

echo "RINOMINO la cartella ${DEST} in ${DESTBK} su prod" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} ${DST} "mv ${DEST} ${DESTBK}" | tee -a ${LOG} 2>${ERR}

echo "COPIO la nuova distribuzione compilata su prod" | tee -a ${LOG} 2>${ERR}
scp -i ${SEC} -pr ${NEWDIST} ${DST}:${DEST} | tee -a ${LOG} 2>${ERR}

cd ${OUT3}
echo "COPIO il tool di migrazione PCMD su prod" | tee -a ${LOG} 2>${ERR}
echo "scp -i ${SEC} -pr pcmd ${DST3}:${DEST3}" | tee -a ${LOG} 2>${ERR}
scp -i ${SEC} -pr pcmd ${DST3}:${DEST3} | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} ${DST3}  "chown -R tomcat:tomcat ${DEST3}/pcmd"  | tee -a ${LOG} 2>${ERR}

exit 0 


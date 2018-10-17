#!/bin/bash

pushd ${PWD}

cd /opt/scripts/project

. .config

[ $# -ne 1 ] && echo -e "Occorre specificare su quale ambiente effettuare il deploy ( stage o prod ) \nEsempio: AGGIORNA.sh stage" && exit 1

TARGETENV=$1

[[ ${TARGETENV,,} == "prod" ]] && echo "La procedura di aggiornamento di prod deve essere configurata" && exit 0

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

echo AMBIENTE: ${TARGETENV} | tee ${LOG} 2>${ERR}

echo Aggiorna Repository | tee -a ${LOG} 2>${ERR}
${BINDIR}/project/prj-update.sh | tee -a ${LOG} 2>${ERR}

[ ${?} -ne 0 ] && echo Aggiornamento Fallito verificare && exit 1

echo Compilazione repository | tee -a ${LOG} 2>${ERR}
${BINDIR}/project/prj-compile_all.sh ${TARGETENV} | tee -a ${LOG} 2>${ERR}

[ ${?} -ne 0 ] && echo Compilazione fallita verificare && exit 2

echo Aggiorna  la distribuzione su ${TARGETENV} | tee -a ${LOG} 2>${ERR}

${BINDIR}/project/dist-update-${TARGETENV}.sh | tee -a ${LOG} 2>${ERR}

[ ${?} -ne 0 ] && echo Distribuzione NON aggiornata verificare && exit 3

echo INIZIO Deploy ${TARGETENV} : `date` | tee -a ${LOG} 2>${ERR}

${BINDIR}/project/dist-deploy-${TARGETENV}.sh | tee -a ${LOG} 2>${ERR}

[ ${?} -ne 0 ] && echo Deploy NON completato verificare && exit 4

echo DEPLOY COMPLETATO | tee -a ${LOG} 2>${ERR}

echo FINE  Deploy STAGE: `date` | tee -a ${LOG} 2>${ERR}

popd

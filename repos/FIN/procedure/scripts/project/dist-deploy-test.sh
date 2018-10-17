#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err

ls -l ${DEST} | tee -a ${LOG} 2>${ERR}

${STOP}

pushd ${PWD}

cd ${JBDP}

for x in `ls -1 c*` ; do
  cksum ${DEST}/deployment-cm/${x} | tee -a ${LOG} 2>${ERR}
  cp ${DEST}/deployment-cm/${x} . | tee -a ${LOG} 2>${ERR}
  cksum ${x} | tee -a ${LOG} 2>${ERR}
done

#Mantiene CFG attuale #unzip -o ${DEST}/deployment-config/config.zip -x solr5/* -d ${CFGDP} | tee -a ${LOG} 2>${ERR}

${JBSTART} | tee -a ${LOG} 2>${ERR}

java -jar ${DEST}/deployment-config/polopoly-cli.jar import -c http://localhost:8081/connection-properties/connection.properties --username sysadmin --password sysadmin ${DEST}/deployment-config/polopoly-imports.jar | tee -a ${LOG} 2>${ERR}
STATUS=${?}
[ ${?} -ne 0 ] && echo Importazione fallita verificare && exit 1

java -jar ${DEST}/deployment-config/polopoly-cli.jar import -c http://localhost:8081/connection-properties/connection.properties --username sysadmin --password sysadmin ${DEST}/deployment-config/project-imports.jar | tee -a ${LOG} 2>${ERR}
STATUS=${?}
[ ${?} -ne 0 ] && echo Importazione fallita verificare && exit 2

cd /opt

for dir in `ls -d tomcat_*` ; do
  echo ${dir} | tee -a ${LOG} 2>${ERR}
  echo Log Backup | tee -a ${LOG} 2>${ERR}
  mkdir -p ${dir}/logs/${BKLOG} | tee -a ${LOG} 2>${ERR}
  mv ${dir}/logs/*.* ${dir}/logs/${BKLOG} | tee -a ${LOG} 2>${ERR}
  
  for file in `ls ${dir}/webapps/*.war` ; do
      FILE=`basename ${file}`
      NAME=`basename ${file} .war`
      DIR=`dirname ${file}`
      [[ -d ${dir}/webapps/${NAME} ]] && rm -rf ${dir}/webapps/${NAME} | tee -a ${LOG} 2>${ERR}
      cksum ${file} | tee -a ${LOG} 2>${ERR}
      [[ -e ${DEST}/deployment-servers/${FILE} ]] && cp ${DEST}/deployment-servers/${FILE} ${dir}/webapps/ | tee -a ${LOG} 2>${ERR} && cksum ${dir}/webapps/${FILE} | tee -a ${LOG} 2>${ERR} && continue;
      [[ -e ${DEST}/deployment-management/${FILE} ]] && cp ${DEST}/deployment-management/${FILE} ${dir}/webapps/ | tee -a ${LOG} 2>${ERR} && cksum ${dir}/webapps/${FILE} | tee -a ${LOG} 2>${ERR} && continue;
      [[ -e ${DEST}/deployment-front/${FILE} && ${dir} == "tomcat_fss" ]] && cp ${DEST}/deployment-front/${FILE} ${dir}/webapps/ | tee -a ${LOG} 2>${ERR} && cksum ${dir}/webapps/${FILE} | tee -a ${LOG} 2>${ERR} && continue;
      [[ -e ${DEST}/deployment-polopoly-gui/${FILE} ]] && cp ${DEST}/deployment-polopoly-gui/${FILE} ${dir}/webapps/ | tee -a ${LOG} 2>${ERR} && cksum ${dir}/webapps/${FILE} | tee -a ${LOG} 2>${ERR} && continue;

  done
done

${TCSTART} | tee -a ${LOG} 2>${ERR}

popd

exit ${STATUS}

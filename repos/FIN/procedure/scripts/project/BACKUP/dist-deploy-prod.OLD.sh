#!/bin/bash
. /opt/scripts/project/.config

FNAME=`basename $0 .sh`
LDIR=log
DATA=`date '+%Y%m%d_%H%M'`
[ ! -d log ] && mkdir -p log
LOG=${PWD}/${LDIR}/${FNAME}_${DATA}.log
ERR=${PWD}/${LDIR}/${FNAME}_${DATA}.err
LOG1=${PWD}/${LDIR}/${FNAME}_imppol_${DATA}.log
ERR1=${PWD}/${LDIR}/${FNAME}_imppol_${DATA}.err
LOG2=${PWD}/${LDIR}/${FNAME}_impprj_${DATA}.log
ERR2=${PWD}/${LDIR}/${FNAME}_impprj_${DATA}.err

#ls -l ${DEST} | tee -a ${LOG} 2>${ERR}

echo "ATTENZIONE:" | tee -a ${LOG} 2>${ERR}

echo "AGGIORNAMENTO POLOPOLY (deploy) sui server di produzione" | tee -a ${LOG} 2>${ERR}

echo "Per aggiornare polopoly verranno fermati i processi ed aggiornati i server di BACKEND:" | tee -a ${LOG} 2>${ERR}
echo "             1) poly-gui3 " | tee -a ${LOG} 2>${ERR}
echo "             2) poly-mediaserver1 " | tee -a ${LOG} 2>${ERR}
echo "             3) poly-bend3 " | tee -a ${LOG} 2>${ERR}
echo "una volta aggiornati i processi saranno riavviati. "  | tee -a ${LOG} 2>${ERR}
echo "" | tee -a ${LOG} 2>${ERR}
echo "A seguire verranno fermati, aggiornati e riavviati i processi sui FRONTEND" | tee -a ${LOG} 2>${ERR}
echo "secondo il seguente ordine:" | tee -a ${LOG} 2>${ERR}
echo "             1) poly-web6" | tee -a ${LOG} 2>${ERR}
echo "             2) poly-web5" | tee -a ${LOG} 2>${ERR}
echo "             3) poly-web4" | tee -a ${LOG} 2>${ERR}


avviadeploy="0"
while [[ ${avviadeploy^^} != "N" ]] && [[ ${avviadeploy^^} != "Y" ]]  
do 
	read -p "Vuoi procedere con il deploy? [y/N] " avviadeploy; 
	echo $avviadeploy
done

if [[ ${avviadeploy} == "N" ]] 
then
   echo "procedura di deploy NON eseguita" | tee -a ${LOG} 2>${ERR}
   exit 0
else
   echo "INIZIO procedura di deploy: `date '+%Y%m%d %H:%M:%S'` " | tee -a ${LOG} 2>${ERR}
fi
 
echo "TOMCAT gui3 "  ###GUI3

cd /opt/svn-project/target/dist/deployment-polopoly-gui 

ssh -i ${SEC} poly-gui3 '/opt/scripts/stop_tomcat.sh' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-gui3 "cd /opt/tomcat/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-polopoly-gui/image.war deployment-polopoly-gui/onecms.war deployment-polopoly-gui/polopoly.war deployment-polopoly-gui/ROOT.war deployment-polopoly-gui/solr.war deployment-polopoly-gui/statistics-gui-2.2.war deployment-management/management.war deployment-servers/act.war poly-gui3:/opt/tomcat/webapps | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} poly-gui3 "cd /opt/tomcat/webapps ; rm -rf image onecms polopoly ROOT solr statistics-gui-2.2 act management ; ls -ltr" | tee -a ${LOG} 2>${ERR}


echo "TOMCAT mediaserver1 " | tee -a ${LOG} 2>${ERR} ##MEDIASERVER1

ssh -i ${SEC} poly-mediaserver1 '/opt/scripts/stop_tomcat.sh' | tee -a ${LOG} 2>${ERR}

cd /opt/svn-project/target/dist/ 

ssh -i ${SEC} poly-mediaserver1 "cd /opt/tomcat/webapps ; rm -rf video-server management file-storage-server integration-server  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} poly-mediaserver1 "cd /opt/tomcat/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-management/management.war  deployment-servers/file-storage-server.war  deployment-servers/integration-server.war  deployment-servers/video-server.war poly-mediaserver1:/opt/tomcat/webapps | tee -a ${LOG} 2>${ERR}


echo "JBOSS e TOMCAT bend3" | tee -a ${LOG} 2>${ERR} ##BEND3

ssh -i ${SEC} poly-bend3 '/opt/scripts/stop_tomcat.sh' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 "cd /opt/tomcat/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 '/opt/scripts/stop_jboss.sh' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 "cd /opt/jboss/server/default/log ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-cm/cm-server-10.16.5.ear deployment-cm/connection-properties-10.16.5.war deployment-cm/content-hub.war poly-bend3:/opt/jboss/server/default/deploy/polopoly | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} poly-bend3 "cd /opt/tomcat/webapps ; rm -rf solr-indexer integration-server solr statistics-server polopoly management ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-servers/statistics-server.war deployment-polopoly-gui/polopoly.war deployment-servers/integration-server.war deployment-servers/solr.war deployment-servers/solr-indexer.war deployment-management/management.war  poly-bend3:/opt/tomcat/webapps | tee -a ${LOG} 2>${ERR}

echo "Avvio JBOSS" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 '/opt/scripts/start_jboss.sh' | tee -a ${LOG} 2>${ERR}

echo "Import fase 1" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 "cd /opt/data/dist ; /usr/bin/java -jar deployment-config/polopoly-cli.jar import -c http://localhost:8081/connection-properties/connection.properties --username sysadmin --password sysadmin deployment-config/polopoly-imports.jar" | tee ${LOG1} 2>${ERR1}

echo "Import fase 2" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 "cd /opt/data/dist ; /usr/bin/java -jar deployment-config/polopoly-cli.jar import -c http://localhost:8081/connection-properties/connection.properties --username sysadmin --password sysadmin deployment-config/project-imports.jar" | tee ${LOG2} 2>${ERR2}

echo "Avvio dei processi backend" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-bend3 '/opt/scripts/start_tomcat.sh'| tee -a ${LOG} 2>${ERR}

echo "Avvio File-Storage ed Integration server" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-mediaserver1 '/opt/scripts/start_tomcat.sh' | tee -a ${LOG} 2>${ERR}

echo "Avvio GUI polopoly" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} poly-gui3 '/opt/scripts/start_tomcat.sh' | tee -a ${LOG} 2>${ERR}

echo "BackEnd ATTIVO - Aggiornamento dei FRONT" | tee -a ${LOG} 2>${ERR}

 
for front in poly-web6 poly-web5 poly-web4
do

read -p "Premi un tasto per proseguire con il deploy del frontend ${front}" frontdeploy; 

echo "Fermo dei processi sul frontend ${front}" | tee -a ${LOG} 2>${ERR}

echo "TOMCAT ${front}" | tee -a ${LOG} 2>${ERR}  ###GUI3

ssh -i ${SEC} ${front} '/opt/scripts/stop_tomcat.sh' | tee -a ${LOG} 2>${ERR}

cd /opt/svn-project/target/dist/ 

ssh -i ${SEC} ${front} "cd /opt/tomcat/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-front/ROOT.war deployment-front/image.war deployment-front/solr.war deployment-servers/video-server.war deployment-servers/file-storage-server.war deployment-management/management.war ${front}:/opt/tomcat/webapps | tee -a ${LOG} 2>${ERR}

echo "cksum dei file da copiare" | tee -a ${LOG} 2>${ERR}
cd /opt/svn-project/target/dist/deployment-front
cksum ROOT.war image.war solr.war  | tee -a ${LOG} 2>${ERR}
cd /opt/svn-project/target/dist/deployment-servers/
cksum video-server.war file-storage-server.war  | tee -a ${LOG} 2>${ERR}
cd /opt/svn-project/target/dist/deployment-management
cksum management.war | tee -a ${LOG} 2>${ERR}
cd /opt/svn-project/target/dist/ 

ssh -i ${SEC} ${front} "cd /opt/tomcat/webapps ; rm -rf management video-server image solr file-storage-server ROOT  ; echo 'cksum dei file copiati ' ; cksum ROOT.war image.war solr.war video-server.war file-storage-server.war management.war" | tee -a ${LOG} 2>${ERR}

echo "Avvio dei processi sul frontend ${front}" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} ${front} '/opt/scripts/start_tomcat.sh' | tee -a ${LOG} 2>${ERR}

done


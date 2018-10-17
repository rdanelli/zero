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

echo "AGGIORNAMENTO POLOPOLY (deploy) sui server di.prod."  | tee -a ${LOG} 2>${ERR}

echo "Per aggiornare polopoly verranno fermati i processi ed aggiornati i server di BACKEND:" | tee -a ${LOG} 2>${ERR}
echo "             1) adm16.prod.fin " | tee -a ${LOG} 2>${ERR}
echo "             2) search16.prod.fin " | tee -a ${LOG} 2>${ERR}
echo "             3) jboss16.prod.fin " | tee -a ${LOG} 2>${ERR}
echo "una volta aggiornati i processi saranno riavviati. "  | tee -a ${LOG} 2>${ERR}
echo "" | tee -a ${LOG} 2>${ERR}
echo "A seguire verranno fermati, aggiornati e riavviati i processi sui FRONTEND" | tee -a ${LOG} 2>${ERR}
#echo "secondo il seguente ordine:" | tee -a ${LOG} 2>${ERR}
echo "             1) fe161.prod.fin" | tee -a ${LOG} 2>${ERR}
echo "             1) fe162.prod.fin" | tee -a ${LOG} 2>${ERR}
echo " " | tee -a ${LOG} 2>${ERR}

avviadeploy="0"
while [[ ${avviadeploy^^} != "N" ]] && [[ ${avviadeploy^^} != "Y" ]]  
do 
	echo $avviadeploy
        if [ $# -eq 0 ] ;  then
           read -p "Vuoi procedere con il deploy? [y/N] " avviadeploy; 
        elif [[ ${1^^} == "JENKINS" ]] ; then
            avviadeploy="Y"
        else
            avviadeploy="N"
        fi
done

if [[ ! ${avviadeploy^^} == "Y" ]] 
then
   echo "procedura di deploy NON eseguita" | tee -a ${LOG} 2>${ERR}
   exit 0
else
   INIZIO=`date '+%Y%m%d %H:%M:%S'`
   echo "INIZIO procedura di deploy: ${INIZIO} " | tee -a ${LOG} 2>${ERR}
fi
 
echo "TOMCAT GUI"  ###adm16.prod.fin

cd ${NEWDIST}

ssh -i ${SEC} adm16.prod.fin '/usr/sbin/service tomcat_gui stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} adm16.prod.fin "cd /opt/tomcat_gui/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-polopoly-gui/image.war deployment-polopoly-gui/onecms.war deployment-polopoly-gui/polopoly.war deployment-polopoly-gui/ROOT.war deployment-polopoly-gui/custom-ws.war deployment-polopoly-gui/login.war deployment-polopoly-gui/workoliday.war adm16.prod.fin:/opt/tomcat_gui/webapps | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} adm16.prod.fin "cd /opt/tomcat_gui/webapps ; rm -rf image onecms polopoly ROOT custom-ws login workoliday ; ls -ltr" | tee -a ${LOG} 2>${ERR}


echo "TOMCAT SOLR-INT " | tee -a ${LOG} 2>${ERR} ##search16.prod.fin

ssh -i ${SEC} search16.prod.fin '/usr/sbin/service tomcat_solr stop' | tee -a ${LOG} 2>${ERR}

cd ${NEWDIST}

ssh -i ${SEC} search16.prod.fin "cd /opt/tomcat_solr/webapps ; rm -rf integration-server solr solr-indexer ; ls -ltr" | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} search16.prod.fin "cd /opt/tomcat_solr/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-servers/integration-server.war deployment-servers/solr.war deployment-servers/solr-indexer.war  search16.prod.fin:/opt/tomcat_solr/webapps | tee -a ${LOG} 2>${ERR}

echo "JBOSS e TOMCAT FSS" | tee -a ${LOG} 2>${ERR} ##jboss16.prod.fin

ssh -i ${SEC} jboss16.prod.fin '/usr/sbin/service tomcat_fss stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin "cd /opt/tomcat_fss/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin '/usr/sbin/service jboss stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin "cd /opt/jboss/server/default/log ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

cd ${NEWDIST}

scp -i ${SEC} deployment-cm/cm-server-10.16.7.ear deployment-cm/connection-properties-10.16.7.war deployment-cm/content-hub.war jboss16.prod.fin:/opt/jboss/server/default/deploy/polopoly | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} jboss16.prod.fin "cd /opt/tomcat_fss/webapps ; rm -rf file-storage-server ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-cm/file-storage-server.war  jboss16.prod.fin:/opt/tomcat_fss/webapps | tee -a ${LOG} 2>${ERR}

echo "Avvio JBOSS" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin '/usr/sbin/service jboss start' | tee -a ${LOG} 2>${ERR}

read -p "Vuoi procedere con la fase di importazione? [y/N] " avviaimport; 

if [[ ! ${avviaimport^^} == "Y" ]]
then
   echo "procedura di import NON eseguita" | tee -a ${LOG} 2>${ERR}
   exit 0
else
   INIZIOIMPPOL=`date '+%Y%m%d %H:%M:%S'`
   echo "INIZIO procedura di import : ${INIZIOIMPPOL} " | tee -a ${LOG} 2>${ERR}
fi

#PASSWORD=P0lyat3x 
PASSWORD=sysadmin

if [[ ! ${1^^} == "JENKINS" ]] ; then
   read -p "Premi un tasto per proseguire " prosegui; 
else
   sleep 5
fi

echo "Import fase 1" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin "cd ${DEST} ; /usr/bin/java -jar deployment-config/polopoly-cli.jar import -c http://localhost:8081/connection-properties/connection.properties --username sysadmin --password ${PASSWORD}  deployment-config/polopoly-imports.jar" | tee ${LOG1} 2>${ERR1}

FINEIMPPOL=`date '+%Y%m%d %H:%M:%S'`
echo "INIZIO import : ${INIZIOIMPPOL} FINE import ${FINEIMPPOL}" | tee -a ${LOG} 2>${ERR}

if [[ ! ${1^^} == "JENKINS" ]] ; then
   read -p "Premi un tasto per proseguire " prosegui; 
else
   sleep 5
fi

INIZIOIMPPRJ=`date '+%Y%m%d %H:%M:%S'`
echo "INIZIO procedura di import : ${INIZIOIMPPRJ} " | tee -a ${LOG} 2>${ERR}

echo "Import fase 2" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin "cd ${DEST} ; /usr/bin/java -jar deployment-config/polopoly-cli.jar import -c http://localhost:8081/connection-properties/connection.properties --username sysadmin --password ${PASSWORD}  deployment-config/project-imports.jar" | tee ${LOG2} 2>${ERR2}

FINEIMPPRJ=`date '+%Y%m%d %H:%M:%S'`
echo "INIZIO import : ${INIZIOIMPPRJ} FINE import ${FINEIMPPRJ}" | tee -a ${LOG} 2>${ERR}

if [[ ! ${1^^} == "JENKINS" ]] ; then
   read -p "Premi un tasto per proseguire " prosegui; 
else
   sleep 5
fi

echo "Avvio dei processi backend" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.prod.fin '/usr/sbin/service tomcat_fss start'| tee -a ${LOG} 2>${ERR}

echo "Avvio File-Storage ed Integration server" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} search16.prod.fin '/usr/sbin/service tomcat_solr start' | tee -a ${LOG} 2>${ERR}

echo "Avvio GUI polopoly" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} adm16.prod.fin '/usr/sbin/service tomcat_gui start' | tee -a ${LOG} 2>${ERR}

echo "BackEnd ATTIVO - Aggiornamento dei FRONT" | tee -a ${LOG} 2>${ERR}

 
for front in fe161.prod.fin fe162.prod.fin
do

if [[ ! ${1^^} == "JENKINS" ]] ; then
   read -p "Premi un tasto per proseguire con il deploy del frontend ${front}" frontdeploy; 
else
   sleep 5
fi

echo "Fermo dei processi sul frontend ${front}" | tee -a ${LOG} 2>${ERR}

echo "TOMCAT ${front}" | tee -a ${LOG} 2>${ERR}  ###GUI3

ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_fe stop' | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_solr stop' | tee -a ${LOG} 2>${ERR}

cd ${NEWDIST}

ssh -i ${SEC} ${front} "cd /opt/tomcat_fe/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} ${front} "cd /opt/tomcat_solr/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-front/ROOT.war deployment-front/image.war deployment-front/custom-ws.war ${front}:/opt/tomcat_fe/webapps | tee -a ${LOG} 2>${ERR}

scp -i ${SEC} deployment-front/solr.war ${front}:/opt/tomcat_solr/webapps | tee -a ${LOG} 2>${ERR}

echo "cksum dei file da copiare" | tee -a ${LOG} 2>${ERR}
cd ${NEWDIST}/deployment-front
cksum solr.war ROOT.war image.war custom-ws.war | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} ${front} "cd /opt/tomcat_solr/webapps ; rm -rf solr ; echo 'cksum dei file copiati ' ; cksum solr.war " | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} ${front} "cd /opt/tomcat_fe/webapps ; rm -rf ROOT image custom-ws  ; echo 'cksum dei file copiati ' ; cksum ROOT.war image.war custom-ws.war" | tee -a ${LOG} 2>${ERR}

echo "Avvio dei processi sul frontend ${front}" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_solr start' | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_fe start' | tee -a ${LOG} 2>${ERR}

done

   FINE=`date '+%Y%m%d %H:%M:%S'`
   echo "INIZIO deploy: ${INIZIO} FINE deploy: ${FINE} " | tee -a ${LOG} 2>${ERR}

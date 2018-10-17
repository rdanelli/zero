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

echo "RIAVVIO processi POLOPOLY sui server di stage"  | tee -a ${LOG} 2>${ERR}

echo "Verranno fermati e riavviati i processi sui server di BACKEND:" | tee -a ${LOG} 2>${ERR}
echo "             1) adm16.stage.fin " | tee -a ${LOG} 2>${ERR}
echo "             2) search16.stage.fin " | tee -a ${LOG} 2>${ERR}
echo "             3) jboss16.stage.fin " | tee -a ${LOG} 2>${ERR}
echo "" | tee -a ${LOG} 2>${ERR}
echo "A seguire verranno fermati, e riavviati i processi sui FRONTEND" | tee -a ${LOG} 2>${ERR}
#echo "secondo il seguente ordine:" | tee -a ${LOG} 2>${ERR}
echo "             1) fe16.stage.fin" | tee -a ${LOG} 2>${ERR}
echo " " | tee -a ${LOG} 2>${ERR}

avviadeploy="0"
while [[ ${avviadeploy^^} != "N" ]] && [[ ${avviadeploy^^} != "Y" ]]  
do 
	#echo $avviadeploy
        if [ $# -eq 0 ] ;  then
           read -p "Vuoi procedere con il Riavvio? [y/N] " avviadeploy; 
        elif [[ ${1^^} == "JENKINS" ]] ; then
            avviadeploy="Y"
        else
            avviadeploy="N"
        fi
done

if [[ ! ${avviadeploy^^} == "Y" ]] 
then
   echo "procedura di RIAVVIO NON eseguita" | tee -a ${LOG} 2>${ERR}
   exit 0
else
   INIZIO=`date '+%Y%m%d %H:%M:%S'`
   echo "INIZIO procedura di RIAVVIO: ${INIZIO} " | tee -a ${LOG} 2>${ERR}
fi
 
echo "TOMCAT GUI"  ###adm16.stage.fin

cd ${NEWDIST}

ssh -i ${SEC} adm16.stage.fin '/usr/sbin/service tomcat_gui stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} adm16.stage.fin "cd /opt/tomcat_gui/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

sleep 5

echo "TOMCAT SOLR-INT " | tee -a ${LOG} 2>${ERR} ##search16.stage.fin

ssh -i ${SEC} search16.stage.fin '/usr/sbin/service tomcat_solr stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} search16.stage.fin "cd /opt/tomcat_solr/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

sleep 5

echo "JBOSS e TOMCAT FSS" | tee -a ${LOG} 2>${ERR} ##jboss16.stage.fin

ssh -i ${SEC} jboss16.stage.fin '/usr/sbin/service tomcat_fss stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.stage.fin "cd /opt/tomcat_fss/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

sleep 5

ssh -i ${SEC} jboss16.stage.fin '/usr/sbin/service jboss stop' | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.stage.fin "cd /opt/jboss/server/default/log ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

sleep 5

echo "Avvio JBOSS" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.stage.fin '/usr/sbin/service jboss start' | tee -a ${LOG} 2>${ERR}

sleep 5

echo "Avvio dei processi backend" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} jboss16.stage.fin '/usr/sbin/service tomcat_fss start'| tee -a ${LOG} 2>${ERR}

sleep 5

echo "Avvio File-Storage ed Integration server" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} search16.stage.fin '/usr/sbin/service tomcat_solr start' | tee -a ${LOG} 2>${ERR}

sleep 5

echo "Avvio GUI polopoly" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} adm16.stage.fin '/usr/sbin/service tomcat_gui start' | tee -a ${LOG} 2>${ERR}

echo "BackEnd ATTIVO - Aggiornamento dei FRONT" | tee -a ${LOG} 2>${ERR}

 
for front in fe16.stage.fin
do

if [[ ! ${1^^} == "JENKINS" ]] ; then
   read -p "Premi un tasto per proseguire con il riavvio del frontend ${front}" frontdeploy; 
else
   sleep 5
fi

echo "Fermo dei processi sul frontend ${front}" | tee -a ${LOG} 2>${ERR}

echo "TOMCAT ${front}" | tee -a ${LOG} 2>${ERR}  ###GUI3

ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_fe stop' | tee -a ${LOG} 2>${ERR}

sleep 5

ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_solr stop' | tee -a ${LOG} 2>${ERR}

sleep 5

ssh -i ${SEC} ${front} "cd /opt/tomcat_fe/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

ssh -i ${SEC} ${front} "cd /opt/tomcat_solr/logs ; mkdir -p backup ; mv *.* backup  ; ls -ltr" | tee -a ${LOG} 2>${ERR}

echo "Avvio dei processi sul frontend ${front}" | tee -a ${LOG} 2>${ERR}
ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_solr start' | tee -a ${LOG} 2>${ERR}

sleep 5

ssh -i ${SEC} ${front} '/usr/sbin/service tomcat_fe start' | tee -a ${LOG} 2>${ERR}

sleep 5

done

FINE=`date '+%Y%m%d %H:%M:%S'`
echo "INIZIO RIAVVIO: ${INIZIO} FINE RIAVVIO: ${FINE} " | tee -a ${LOG} 2>${ERR}


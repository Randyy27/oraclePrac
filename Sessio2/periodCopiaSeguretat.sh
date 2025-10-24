# Variables d'entorn
export ORACLE_SID=FREE
export ORACLE_HOME=/opt/oracle/product/23ai/dbhomeFree
export PATH=$ORACLE_HOME/bin:$PATH

# Data actual per al log
DATA=$(date +%Y%m%d_%H%M)

# Execució de la còpia de seguretat amb RMAN
rman target / cmdfile=/home/oracle/scripts/copiaSeguretat-02.rman log=/home/oracle/backup/backup_${DATA}.log

# Sortida
echo "Còpia de seguretat completada el $(date)" >> /home/oracle/backup/backup_history.log

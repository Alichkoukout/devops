#!/bin/bash

# Configuration
ELASTIC_PASSWORD="production_elastic_password"
BACKUP_DIR="/opt/monitoring/backup/indices"
DATE=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_NAME="snapshot_$DATE"

# Créer le répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Configurer le repository de sauvegarde
curl -X PUT "http://localhost:9200/_snapshot/backup" \
     -H "Content-Type: application/json" \
     -u elastic:$ELASTIC_PASSWORD \
     -d '{
       "type": "fs",
       "settings": {
         "location": "'$BACKUP_DIR'",
         "compress": true
       }
     }'

# Créer le snapshot
curl -X PUT "http://localhost:9200/_snapshot/backup/$SNAPSHOT_NAME?wait_for_completion=true" \
     -H "Content-Type: application/json" \
     -u elastic:$ELASTIC_PASSWORD \
     -d '{
       "indices": "filebeat-*,logstash-*",
       "ignore_unavailable": true,
       "include_global_state": false
     }'

# Vérifier le statut du snapshot
curl -X GET "http://localhost:9200/_snapshot/backup/$SNAPSHOT_NAME" \
     -u elastic:$ELASTIC_PASSWORD

# Supprimer les anciens snapshots (garder les 7 derniers jours)
OLD_SNAPSHOTS=$(curl -s -X GET "http://localhost:9200/_snapshot/backup/_all" \
     -u elastic:$ELASTIC_PASSWORD | jq -r '.snapshots[] | select(.start_time < (now - 7*24*60*60*1000)) | .snapshot')

for snapshot in $OLD_SNAPSHOTS; do
    curl -X DELETE "http://localhost:9200/_snapshot/backup/$snapshot" \
         -u elastic:$ELASTIC_PASSWORD
done

echo "Sauvegarde des index terminée : $SNAPSHOT_NAME" 
#!/bin/bash

# Configuration des variables
BACKUP_DIR="/opt/monitoring/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/monitoring_backup_$DATE.tar.gz"
ELASTICSEARCH_DIR="/etc/elasticsearch"
KIBANA_DIR="/etc/kibana"
LOGSTASH_DIR="/etc/logstash"
FILEBEAT_DIR="/etc/filebeat"

# Fonction pour vérifier l'espace disque
check_disk_space() {
    local required_space=1000 # 1GB en MB
    local available_space=$(df -m "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        echo "✗ Espace disque insuffisant pour la sauvegarde"
        echo "Espace disponible: ${available_space}MB"
        echo "Espace requis: ${required_space}MB"
        return 1
    fi
    return 0
}

# Fonction pour nettoyer les anciennes sauvegardes
cleanup_old_backups() {
    echo "Nettoyage des anciennes sauvegardes..."
    find "$BACKUP_DIR" -name "monitoring_backup_*.tar.gz" -mtime +7 -delete
    find "$BACKUP_DIR/elasticsearch" -name "snapshot_*" -mtime +7 -delete
}

# 1. Vérifier l'espace disque
echo "1. Vérification de l'espace disque..."
if ! check_disk_space; then
    exit 1
fi

# 2. Créer le répertoire de backup
echo "1. Création du répertoire de backup..."
mkdir -p "$BACKUP_DIR"

# 2. Sauvegarder les configurations
echo "2. Sauvegarde des configurations..."

# Créer un fichier temporaire pour la liste des fichiers à sauvegarder
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
$ELASTICSEARCH_DIR/elasticsearch.yml
$ELASTICSEARCH_DIR/jvm.options
$ELASTICSEARCH_DIR/log4j2.properties
$KIBANA_DIR/kibana.yml
$LOGSTASH_DIR/logstash.yml
$LOGSTASH_DIR/pipelines.yml
$LOGSTASH_DIR/patterns/
$FILEBEAT_DIR/filebeat.yml
/opt/monitoring/.env
EOF

# Créer l'archive
tar -czf "$BACKUP_FILE" -T "$TEMP_FILE"

# Supprimer le fichier temporaire
rm "$TEMP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Sauvegarde créée avec succès: $BACKUP_FILE"
else
    echo "✗ Erreur lors de la création de la sauvegarde"
    exit 1
fi

# 3. Sauvegarder les données Elasticsearch
echo "3. Sauvegarde des données Elasticsearch..."
curl -X PUT "localhost:9200/_snapshot/monitoring_backup" -H "Content-Type: application/json" -d '{
    "type": "fs",
    "settings": {
        "location": "'$BACKUP_DIR'/elasticsearch"
    }
}'

curl -X PUT "localhost:9200/_snapshot/monitoring_backup/snapshot_$DATE?wait_for_completion=true"

if [ $? -eq 0 ]; then
    echo "✓ Données Elasticsearch sauvegardées avec succès"
else
    echo "✗ Erreur lors de la sauvegarde des données Elasticsearch"
fi

# 4. Nettoyer les anciennes sauvegardes (garder les 7 derniers jours)
echo "4. Nettoyage des anciennes sauvegardes..."
cleanup_old_backups

# 5. Vérification
echo "5. Vérification de la sauvegarde..."
if [ -f "$BACKUP_FILE" ]; then
    echo "✓ La sauvegarde a été créée avec succès"
    echo "Emplacement: $BACKUP_FILE"
    echo "Taille: $(du -h "$BACKUP_FILE" | cut -f1)"
else
    echo "✗ La sauvegarde n'a pas été créée"
    exit 1
fi

echo "=== Sauvegarde des configurations terminée ===" 
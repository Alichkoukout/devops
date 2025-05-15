#!/bin/bash

# Vérifier si un fichier de backup est spécifié
if [ -z "$1" ]; then
    echo "Usage: $0 <chemin_vers_backup.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="/opt/monitoring/backups"
RESTORE_DIR="/tmp/monitoring_restore_$(date +%Y%m%d_%H%M%S)"

# 1. Vérifier que le fichier de backup existe
echo "1. Vérification du fichier de backup..."
if [ ! -f "$BACKUP_FILE" ]; then
    echo "✗ Le fichier de backup n'existe pas: $BACKUP_FILE"
    exit 1
fi

# 2. Créer le répertoire de restauration
echo "2. Création du répertoire de restauration..."
mkdir -p "$RESTORE_DIR"

# 3. Extraire le backup
echo "3. Extraction du backup..."
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

if [ $? -ne 0 ]; then
    echo "✗ Erreur lors de l'extraction du backup"
    exit 1
fi

# 4. Restaurer les configurations
echo "4. Restauration des configurations..."

# Elasticsearch
echo "Restauration d'Elasticsearch..."
cp "$RESTORE_DIR/etc/elasticsearch/elasticsearch.yml" "/etc/elasticsearch/"
cp "$RESTORE_DIR/etc/elasticsearch/jvm.options" "/etc/elasticsearch/"
cp "$RESTORE_DIR/etc/elasticsearch/log4j2.properties" "/etc/elasticsearch/"

# Kibana
echo "Restauration de Kibana..."
cp "$RESTORE_DIR/etc/kibana/kibana.yml" "/etc/kibana/"

# Logstash
echo "Restauration de Logstash..."
cp "$RESTORE_DIR/etc/logstash/logstash.yml" "/etc/logstash/"
cp "$RESTORE_DIR/etc/logstash/pipelines.yml" "/etc/logstash/"
cp -r "$RESTORE_DIR/etc/logstash/patterns/" "/etc/logstash/"

# Filebeat
echo "Restauration de Filebeat..."
cp "$RESTORE_DIR/etc/filebeat/filebeat.yml" "/etc/filebeat/"

# Variables d'environnement
echo "Restauration des variables d'environnement..."
cp "$RESTORE_DIR/opt/monitoring/.env" "/opt/monitoring/"

# 5. Restaurer les données Elasticsearch
echo "5. Restauration des données Elasticsearch..."
SNAPSHOT_NAME=$(basename "$BACKUP_FILE" .tar.gz | sed 's/monitoring_backup_/snapshot_/')

# Vérifier si le repository existe
if ! curl -s "localhost:9200/_snapshot/monitoring_backup" > /dev/null; then
    # Créer le repository
    curl -X PUT "localhost:9200/_snapshot/monitoring_backup" -H "Content-Type: application/json" -d '{
        "type": "fs",
        "settings": {
            "location": "'$BACKUP_DIR'/elasticsearch"
        }
    }'
fi

# Restaurer le snapshot
curl -X POST "localhost:9200/_snapshot/monitoring_backup/$SNAPSHOT_NAME/_restore?wait_for_completion=true"

if [ $? -eq 0 ]; then
    echo "✓ Données Elasticsearch restaurées avec succès"
else
    echo "✗ Erreur lors de la restauration des données Elasticsearch"
fi

# 6. Configurer les permissions
echo "6. Configuration des permissions..."
chown -R elasticsearch:elasticsearch /etc/elasticsearch
chown -R kibana:kibana /etc/kibana
chown -R logstash:logstash /etc/logstash
chown -R root:root /etc/filebeat
chmod 640 /opt/monitoring/.env

# 7. Nettoyage
echo "7. Nettoyage..."
rm -rf "$RESTORE_DIR"

# 8. Redémarrer les services
echo "8. Redémarrage des services..."
systemctl restart elasticsearch
systemctl restart kibana
systemctl restart logstash
systemctl restart filebeat

# 9. Vérification
echo "9. Vérification de la restauration..."
sleep 30  # Attendre que les services soient prêts

# Vérifier Elasticsearch
if curl -s "localhost:9200/_cluster/health" > /dev/null; then
    echo "✓ Elasticsearch est opérationnel"
else
    echo "✗ Elasticsearch n'est pas opérationnel"
fi

# Vérifier Kibana
if curl -s "localhost:5601/api/status" > /dev/null; then
    echo "✓ Kibana est opérationnel"
else
    echo "✗ Kibana n'est pas opérationnel"
fi

# Vérifier Logstash
if curl -s "localhost:9600/_node/stats" > /dev/null; then
    echo "✓ Logstash est opérationnel"
else
    echo "✗ Logstash n'est pas opérationnel"
fi

echo "=== Restauration des configurations terminée ===" 
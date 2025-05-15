#!/bin/bash

# Configuration des variables
LOG_DIR="/var/log/monitoring"
RETENTION_DAYS=7
MAX_SIZE="100M"
MAX_FILES=7

# Fonction pour créer une configuration de rotation
create_rotation_config() {
    local log_name=$1
    local log_path=$2

    echo "Configuration de la rotation pour $log_name..."
    
    cat > "/etc/logrotate.d/$log_name" << EOF
$log_path {
    daily
    rotate $MAX_FILES
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    size $MAX_SIZE
    dateext
    dateformat -%Y%m%d
    sharedscripts
    postrotate
        /usr/bin/systemctl reload elasticsearch > /dev/null 2>&1 || true
        /usr/bin/systemctl reload kibana > /dev/null 2>&1 || true
        /usr/bin/systemctl reload logstash > /dev/null 2>&1 || true
    endscript
}
EOF

    if [ $? -eq 0 ]; then
        echo "✓ Configuration de rotation créée pour $log_name"
        return 0
    else
        echo "✗ Erreur lors de la création de la configuration de rotation pour $log_name"
        return 1
    fi
}

# 1. Créer le répertoire des logs
echo "1. Création du répertoire des logs..."
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# 2. Configurer la rotation pour chaque service
echo "2. Configuration de la rotation des logs..."

# Elasticsearch
create_rotation_config "elasticsearch" "$LOG_DIR/elasticsearch.log"

# Kibana
create_rotation_config "kibana" "$LOG_DIR/kibana.log"

# Logstash
create_rotation_config "logstash" "$LOG_DIR/logstash.log"

# Filebeat
create_rotation_config "filebeat" "$LOG_DIR/filebeat.log"

# 3. Configurer la rotation des logs d'application
echo "3. Configuration de la rotation des logs d'application..."

# Logs d'application
create_rotation_config "application" "$LOG_DIR/application.log"

# Logs de sécurité
create_rotation_config "security" "$LOG_DIR/security.log"

# Logs de performance
create_rotation_config "performance" "$LOG_DIR/performance.log"

# 4. Configurer la rotation des logs système
echo "4. Configuration de la rotation des logs système..."

# Logs système
create_rotation_config "system" "$LOG_DIR/system.log"

# Logs réseau
create_rotation_config "network" "$LOG_DIR/network.log"

# 5. Vérification
echo "5. Vérification des configurations..."
if [ -d "/etc/logrotate.d" ] && [ -f "/etc/logrotate.d/elasticsearch" ] && [ -f "/etc/logrotate.d/kibana" ] && [ -f "/etc/logrotate.d/logstash" ]; then
    echo "✓ Toutes les configurations de rotation sont en place"
else
    echo "✗ Erreur: Certaines configurations sont manquantes"
    exit 1
fi

# 6. Test de la rotation
echo "6. Test de la rotation des logs..."
logrotate -d /etc/logrotate.d/*

if [ $? -eq 0 ]; then
    echo "✓ Test de rotation réussi"
else
    echo "✗ Erreur lors du test de rotation"
    exit 1
fi

echo "=== Configuration de la rotation des logs terminée ===" 
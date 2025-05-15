#!/bin/bash

# Configuration des variables
LOG_DIR="/var/log"
RETENTION_DAYS=30
MAX_SIZE="100M"

# Fonction pour configurer la rotation des logs
configure_log_rotation() {
    local service=$1
    local log_file=$2
    local pattern=$3

    echo "Configuration de la rotation des logs pour $service..."
    
    # Créer la configuration logrotate
    cat > "/etc/logrotate.d/$service" << EOF
$log_file {
    daily
    rotate $RETENTION_DAYS
    compress
    delaycompress
    missingok
    notifempty
    create 0640 $service $service
    sharedscripts
    postrotate
        systemctl reload $service >/dev/null 2>&1 || true
    endscript
}
EOF

    # Vérifier si le fichier de log existe
    if [ ! -f "$log_file" ]; then
        echo "Création du fichier de log: $log_file"
        touch "$log_file"
        chown $service:$service "$log_file"
        chmod 640 "$log_file"
    fi

    # Configurer les permissions
    chmod 644 "/etc/logrotate.d/$service"
}

# 1. Configuration de la rotation des logs Elasticsearch
echo "1. Configuration de la rotation des logs Elasticsearch..."
configure_log_rotation "elasticsearch" "/var/log/elasticsearch/elasticsearch.log" "elasticsearch-*.log"

# 2. Configuration de la rotation des logs Kibana
echo "2. Configuration de la rotation des logs Kibana..."
configure_log_rotation "kibana" "/var/log/kibana/kibana.log" "kibana-*.log"

# 3. Configuration de la rotation des logs Logstash
echo "3. Configuration de la rotation des logs Logstash..."
configure_log_rotation "logstash" "/var/log/logstash/logstash.log" "logstash-*.log"

# 4. Configuration de la rotation des logs Filebeat
echo "4. Configuration de la rotation des logs Filebeat..."
configure_log_rotation "filebeat" "/var/log/filebeat/filebeat.log" "filebeat-*.log"

# 5. Configuration de la rotation des logs système
echo "5. Configuration de la rotation des logs système..."
cat > "/etc/logrotate.d/syslog" << EOF
/var/log/syslog
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/lpr.log
/var/log/cron.log
/var/log/debug
/var/log/messages
{
    daily
    rotate $RETENTION_DAYS
    compress
    delaycompress
    missingok
    notifempty
    create 0640 syslog adm
    sharedscripts
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOF

# 6. Configuration de la rotation des logs d'application
echo "6. Configuration de la rotation des logs d'application..."
cat > "/etc/logrotate.d/application" << EOF
/var/log/application/*.log {
    daily
    rotate $RETENTION_DAYS
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        systemctl reload application >/dev/null 2>&1 || true
    endscript
}
EOF

# 7. Vérification des configurations
echo "7. Vérification des configurations..."
for service in elasticsearch kibana logstash filebeat syslog application; do
    if [ -f "/etc/logrotate.d/$service" ]; then
        echo "✓ Configuration créée pour $service"
    else
        echo "✗ Erreur: Configuration manquante pour $service"
        exit 1
    fi
done

# 8. Test de la rotation
echo "8. Test de la rotation des logs..."
logrotate -d /etc/logrotate.conf

# 9. Configuration des permissions
echo "9. Configuration des permissions..."
chmod 644 /etc/logrotate.d/*
chown root:root /etc/logrotate.d/*

echo "=== Configuration de la rotation des logs terminée ==="
echo "Les logs seront conservés pendant $RETENTION_DAYS jours"
echo "La taille maximale des fichiers de log est de $MAX_SIZE" 
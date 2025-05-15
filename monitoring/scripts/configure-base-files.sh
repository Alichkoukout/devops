#!/bin/bash

# Configuration des variables
CONFIG_DIR="/etc"
CERT_DIR="/opt/monitoring/certs"

# Fonction pour créer un répertoire avec les permissions appropriées
create_dir() {
    local dir=$1
    local owner=$2
    local perms=$3
    
    echo "Création du répertoire: $dir..."
    mkdir -p "$dir"
    chown "$owner:$owner" "$dir"
    chmod "$perms" "$dir"
    echo "✓ Répertoire créé: $dir"
}

# 1. Créer les répertoires nécessaires
echo "1. Création des répertoires..."
create_dir "/opt/monitoring/certs" "root" "755"
create_dir "/var/log/elasticsearch" "elasticsearch" "755"
create_dir "/var/log/kibana" "kibana" "755"
create_dir "/var/log/logstash" "logstash" "755"
create_dir "/var/log/filebeat" "filebeat" "755"

# 2. Configuration d'Elasticsearch
echo "2. Configuration d'Elasticsearch..."
cat > "$CONFIG_DIR/elasticsearch/elasticsearch.yml" << EOF
cluster.name: monitoring-cluster
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: $CERT_DIR/elasticsearch/elasticsearch.keystore
xpack.security.transport.ssl.truststore.path: $CERT_DIR/elasticsearch/elasticsearch.truststore
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: $CERT_DIR/elasticsearch/elasticsearch.keystore
xpack.security.http.ssl.truststore.path: $CERT_DIR/elasticsearch/elasticsearch.truststore
EOF

# 3. Configuration de Kibana
echo "3. Configuration de Kibana..."
cat > "$CONFIG_DIR/kibana/kibana.yml" << EOF
server.name: kibana
server.host: "0.0.0.0"
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.username: kibana
elasticsearch.password: ${KIBANA_PASSWORD}
elasticsearch.ssl.certificateAuthorities: ["$CERT_DIR/ca/ca.crt"]
elasticsearch.ssl.verificationMode: certificate
xpack.security.encryptionKey: "${ENCRYPTION_KEY:-$(openssl rand -hex 32)}"
xpack.reporting.encryptionKey: "${REPORTING_KEY:-$(openssl rand -hex 32)}"
EOF

# 4. Configuration de Logstash
echo "4. Configuration de Logstash..."
cat > "$CONFIG_DIR/logstash/logstash.yml" << EOF
http.host: "0.0.0.0"
xpack.monitoring.enabled: true
xpack.monitoring.elasticsearch.hosts: ["https://localhost:9200"]
xpack.monitoring.elasticsearch.username: logstash
xpack.monitoring.elasticsearch.password: ${LOGSTASH_PASSWORD}
xpack.monitoring.elasticsearch.ssl.certificate_authority: "$CERT_DIR/ca/ca.crt"
EOF

# 5. Configuration de Filebeat
echo "5. Configuration de Filebeat..."
cat > "$CONFIG_DIR/filebeat/filebeat.yml" << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/application/*.log
  fields:
    type: application
  fields_under_root: true

output.elasticsearch:
  hosts: ["https://localhost:9200"]
  username: filebeat
  password: ${FILEBEAT_PASSWORD}
  ssl.certificate_authorities: ["$CERT_DIR/ca/ca.crt"]
  ssl.verification_mode: certificate

setup.kibana:
  host: "https://localhost:5601"
  username: elastic
  password: ${ELASTIC_PASSWORD}
  ssl.certificate_authorities: ["$CERT_DIR/ca/ca.crt"]
  ssl.verification_mode: certificate

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
EOF

# 6. Configuration de logrotate
echo "6. Configuration de logrotate..."
cat > "/etc/logrotate.d/monitoring" << EOF
/var/log/elasticsearch/*.log
/var/log/kibana/*.log
/var/log/logstash/*.log
/var/log/filebeat/*.log
/var/log/application/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        systemctl reload elasticsearch >/dev/null 2>&1 || true
        systemctl reload kibana >/dev/null 2>&1 || true
        systemctl reload logstash >/dev/null 2>&1 || true
        systemctl reload filebeat >/dev/null 2>&1 || true
    endscript
}
EOF

# 7. Configuration des permissions
echo "7. Configuration des permissions..."
chown -R elasticsearch:elasticsearch "$CONFIG_DIR/elasticsearch"
chown -R kibana:kibana "$CONFIG_DIR/kibana"
chown -R logstash:logstash "$CONFIG_DIR/logstash"
chown -R filebeat:filebeat "$CONFIG_DIR/filebeat"

chmod 644 "$CONFIG_DIR/elasticsearch/elasticsearch.yml"
chmod 644 "$CONFIG_DIR/kibana/kibana.yml"
chmod 644 "$CONFIG_DIR/logstash/logstash.yml"
chmod 644 "$CONFIG_DIR/filebeat/filebeat.yml"

# 8. Vérification
echo "8. Vérification des configurations..."
for file in \
    "$CONFIG_DIR/elasticsearch/elasticsearch.yml" \
    "$CONFIG_DIR/kibana/kibana.yml" \
    "$CONFIG_DIR/logstash/logstash.yml" \
    "$CONFIG_DIR/filebeat/filebeat.yml" \
    "/etc/logrotate.d/monitoring"; do
    if [ -f "$file" ]; then
        echo "✓ Fichier créé: $file"
    else
        echo "✗ Erreur: Fichier manquant: $file"
        exit 1
    fi
done

echo "Configuration des fichiers de base terminée!" 
#!/bin/bash

# Configuration des variables
KIBANA_DIR="/etc/kibana"
CONFIG_DIR="$KIBANA_DIR/config"
CERT_DIR="/opt/monitoring/certs"
ES_URL="http://localhost:9200"
KIBANA_URL="http://localhost:5601"
ES_USER="elastic"
ES_PASSWORD="${ELASTIC_PASSWORD}"
KIBANA_USER="kibana"
KIBANA_PASSWORD="${KIBANA_PASSWORD}"

# Fonction pour importer une configuration
import_config() {
    local type=$1
    local file=$2
    local name=$3

    echo "Import de la configuration $type: $name..."
    
    # Vérifier si la configuration existe déjà
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=$type&search_fields=title&search=$name" | grep -q "\"total\":0"; then
        # Importer la configuration
        curl -s -X POST -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/$type/$name" \
            -d @"$file"
        
        if [ $? -eq 0 ]; then
            echo "✓ Configuration $name importée avec succès"
            return 0
        else
            echo "✗ Erreur lors de l'import de la configuration $name"
            return 1
        fi
    else
        echo "! Configuration $name existe déjà, mise à jour..."
        curl -s -X PUT -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/$type/$name" \
            -d @"$file"
        
        if [ $? -eq 0 ]; then
            echo "✓ Configuration $name mise à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour de la configuration $name"
            return 1
        fi
    fi
}

# 1. Créer le répertoire de configuration
echo "1. Création du répertoire de configuration..."
mkdir -p "$CONFIG_DIR"

# 2. Configurer kibana.yml
echo "2. Configuration de kibana.yml..."
cat > "$KIBANA_DIR/kibana.yml" << EOF
server.host: "0.0.0.0"
server.ssl.enabled: true
server.ssl.certificate: "$CERT_DIR/kibana.crt"
server.ssl.key: "$CERT_DIR/kibana.key"
server.ssl.certificateAuthorities: ["$CERT_DIR/ca.crt"]

elasticsearch.hosts: ["$ES_URL"]
elasticsearch.username: "$KIBANA_USER"
elasticsearch.password: "$KIBANA_PASSWORD"
elasticsearch.ssl.enabled: true
elasticsearch.ssl.verificationMode: certificate
elasticsearch.ssl.certificateAuthorities: ["$CERT_DIR/ca.crt"]

xpack.security.enabled: true
xpack.encryptedSavedObjects.encryptionKey: "something_at_least_32_characters_long"
xpack.reporting.encryptionKey: "something_at_least_32_characters_long"
xpack.security.audit.enabled: true

monitoring.ui.container.elasticsearch.enabled: true
EOF

# 3. Créer les configurations de base
echo "3. Création des configurations de base..."

# Dashboard système
cat > "$CONFIG_DIR/system-dashboard.json" << EOF
{
  "attributes": {
    "title": "System Overview",
    "hits": 0,
    "description": "Dashboard pour la surveillance système",
    "panelsJSON": "[{\"type\":\"visualization\",\"id\":\"system-metrics\",\"panelIndex\":\"1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":15,\"i\":\"1\"}}]",
    "optionsJSON": "{\"hidePanelTitles\":false,\"useMargins\":true}",
    "version": 1,
    "timeRestore": false,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}
EOF

# Dashboard application
cat > "$CONFIG_DIR/application-dashboard.json" << EOF
{
  "attributes": {
    "title": "Application Overview",
    "hits": 0,
    "description": "Dashboard pour la surveillance des applications",
    "panelsJSON": "[{\"type\":\"visualization\",\"id\":\"application-metrics\",\"panelIndex\":\"1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":15,\"i\":\"1\"}}]",
    "optionsJSON": "{\"hidePanelTitles\":false,\"useMargins\":true}",
    "version": 1,
    "timeRestore": false,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}
EOF

# Dashboard sécurité
cat > "$CONFIG_DIR/security-dashboard.json" << EOF
{
  "attributes": {
    "title": "Security Overview",
    "hits": 0,
    "description": "Dashboard pour la surveillance de la sécurité",
    "panelsJSON": "[{\"type\":\"visualization\",\"id\":\"security-events\",\"panelIndex\":\"1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":15,\"i\":\"1\"}}]",
    "optionsJSON": "{\"hidePanelTitles\":false,\"useMargins\":true}",
    "version": 1,
    "timeRestore": false,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}
EOF

# 4. Importer les configurations
echo "4. Import des configurations..."

# Attendre que Kibana soit prêt
echo "Attente de Kibana..."
for i in $(seq 1 30); do
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/status" > /dev/null; then
        echo "Kibana est prêt!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ Timeout: Kibana n'est pas prêt"
        exit 1
    fi
    echo "Tentative $i/30..."
    sleep 10
done

# Importer les dashboards
import_config "dashboard" "$CONFIG_DIR/system-dashboard.json" "system-overview"
import_config "dashboard" "$CONFIG_DIR/application-dashboard.json" "application-overview"
import_config "dashboard" "$CONFIG_DIR/security-dashboard.json" "security-overview"

# 5. Configurer les permissions
echo "5. Configuration des permissions..."
chown -R kibana:kibana "$KIBANA_DIR"
chmod -R 750 "$KIBANA_DIR"
chmod 640 "$KIBANA_DIR/kibana.yml"
chmod 640 "$CONFIG_DIR"/*.json

# 6. Vérification
echo "6. Vérification des configurations..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=dashboard" | grep -q "\"total\":3"; then
    echo "✓ Toutes les configurations sont importées"
else
    echo "✗ Erreur: Certaines configurations sont manquantes"
    exit 1
fi

echo "=== Import des configurations Kibana terminé ===" 
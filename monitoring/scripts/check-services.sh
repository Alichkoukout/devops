#!/bin/bash

# Configuration des variables
ELASTICSEARCH_URL="http://localhost:9200"
KIBANA_URL="http://localhost:5601"
LOGSTASH_URL="http://localhost:9600"
ELASTIC_USER="elastic"
ELASTIC_PASSWORD="${ELASTIC_PASSWORD}"
KIBANA_USER="kibana"
KIBANA_PASSWORD="${KIBANA_PASSWORD}"
LOGSTASH_USER="logstash"
LOGSTASH_PASSWORD="${LOGSTASH_PASSWORD}"

# Fonction pour vérifier un service
check_service() {
    local name=$1
    local url=$2
    local user=$3
    local password=$4

    echo "Vérification du service $name..."
    
    if curl -s -u "$user:$password" "$url" > /dev/null; then
        echo "✓ Service $name est opérationnel"
        return 0
    else
        echo "✗ Service $name n'est pas disponible"
        return 1
    fi
}

# 1. Vérifier Elasticsearch
check_service "Elasticsearch" "$ELASTICSEARCH_URL" "$ELASTIC_USER" "$ELASTIC_PASSWORD"

# 2. Vérifier Kibana
check_service "Kibana" "$KIBANA_URL/api/status" "$KIBANA_USER" "$KIBANA_PASSWORD"

# 3. Vérifier Logstash
check_service "Logstash" "$LOGSTASH_URL/_node/stats" "$LOGSTASH_USER" "$LOGSTASH_PASSWORD"

# 4. Vérifier les indices Elasticsearch
echo "Vérification des indices Elasticsearch..."
if curl -s -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTICSEARCH_URL/_cat/indices" | grep -q "filebeat\|application\|security\|metrics\|error"; then
    echo "✓ Les indices sont présents"
else
    echo "✗ Certains indices sont manquants"
fi

# 5. Vérifier les pipelines Logstash
echo "Vérification des pipelines Logstash..."
if curl -s -u "$LOGSTASH_USER:$LOGSTASH_PASSWORD" "$LOGSTASH_URL/_node/pipelines" | grep -q "\"total\":5"; then
    echo "✓ Les pipelines sont configurés"
else
    echo "✗ Certains pipelines sont manquants"
fi

# 6. Vérifier les dashboards Kibana
echo "Vérification des dashboards Kibana..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=dashboard" | grep -q "\"total\":5"; then
    echo "✓ Les dashboards sont configurés"
else
    echo "✗ Certains dashboards sont manquants"
fi

# 7. Vérifier les alertes Kibana
echo "Vérification des alertes Kibana..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/alerting/rules/_find" | grep -q "\"total\":5"; then
    echo "✓ Les alertes sont configurées"
else
    echo "✗ Certaines alertes sont manquantes"
fi

echo "=== Vérification des services terminée ===" 
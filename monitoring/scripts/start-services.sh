#!/bin/bash

# Configuration des variables
ES_URL="http://localhost:9200"
KIBANA_URL="http://localhost:5601"
LOGSTASH_URL="http://localhost:9600"
ES_USER="elastic"
ES_PASSWORD="${ELASTIC_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour démarrer un service
start_service() {
    local service=$1
    local url=$2
    local auth=$3
    local retries=0

    echo "Démarrage de $service..."
    systemctl start $service

    # Attendre que le service soit prêt
    while [ $retries -lt $MAX_RETRIES ]; do
        if [ -n "$auth" ]; then
            response=$(curl -s -u "$auth" "$url")
        else
            response=$(curl -s "$url")
        fi

        if [ $? -eq 0 ] && [ -n "$response" ]; then
            echo "✓ $service est prêt"
            return 0
        fi

        echo "En attente de $service... ($((retries + 1))/$MAX_RETRIES)"
        sleep $RETRY_INTERVAL
        retries=$((retries + 1))
    done

    echo "✗ $service n'a pas démarré correctement"
    return 1
}

# 1. Démarrer Elasticsearch
start_service "elasticsearch" "$ES_URL" "$ES_USER:$ES_PASSWORD"
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de démarrer Elasticsearch"
    exit 1
fi

# 2. Démarrer Kibana
start_service "kibana" "$KIBANA_URL" "$ES_USER:$ES_PASSWORD"
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de démarrer Kibana"
    exit 1
fi

# 3. Démarrer Logstash
start_service "logstash" "$LOGSTASH_URL"
if [ $? -ne 0 ]; then
    echo "Erreur: Impossible de démarrer Logstash"
    exit 1
fi

# 4. Démarrer Filebeat
echo "Démarrage de Filebeat..."
systemctl start filebeat
if [ $? -eq 0 ]; then
    echo "✓ Filebeat démarré"
else
    echo "✗ Erreur lors du démarrage de Filebeat"
    exit 1
fi

# 5. Vérifier les services
echo "Vérification des services..."
./monitoring/scripts/check-services.sh

echo "=== Démarrage des services terminé ==="
echo "Kibana est accessible à l'adresse: $KIBANA_URL"
echo "Utilisez les identifiants suivants pour vous connecter:"
echo "Utilisateur: $ES_USER"
echo "Mot de passe: $ES_PASSWORD" 
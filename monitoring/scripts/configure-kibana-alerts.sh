#!/bin/bash

# Vérifier si Kibana est prêt
echo "Vérification de Kibana..."
until curl -s http://localhost:5601 > /dev/null; do
    echo "En attente de Kibana..."
    sleep 5
done

# Configuration des variables
KIBANA_URL="http://localhost:5601"
KIBANA_USER="elastic"
KIBANA_PASSWORD="${ELASTIC_PASSWORD}"

# Fonction pour créer une alerte
create_alert() {
    local name=$1
    local condition=$2
    local threshold=$3
    
    echo "Création de l'alerte: $name"
    response=$(curl -s -X POST "$KIBANA_URL/api/alerting/rule" \
        -H "kbn-xsrf: true" \
        -H "Content-Type: application/json" \
        -u "$KIBANA_USER:$KIBANA_PASSWORD" \
        -d '{
            "name": "'"$name"'",
            "consumer": "alerts",
            "tags": ["monitoring"],
            "rule_type_id": "threshold",
            "schedule": {
                "interval": "1m"
            },
            "params": {
                "index": ["filebeat-*"],
                "timeField": "@timestamp",
                "timeWindowSize": 5,
                "timeWindowUnit": "m",
                "threshold": ['"$threshold"'],
                "thresholdComparator": ">",
                "aggType": "count",
                "groupBy": "all",
                "termSize": 5,
                "termField": "level",
                "filter": "'"$condition"'"
            },
            "actions": [
                {
                    "group": "threshold met",
                    "id": "slack",
                    "params": {
                        "message": "Alerte: '"$name"' - {{context.value}} occurrences détectées"
                    }
                }
            ]
        }')
    
    if [[ $response == *"\"id\":"* ]]; then
        echo "✓ Alerte créée avec succès"
    else
        echo "✗ Échec de la création de l'alerte: $response"
        return 1
    fi
}

# 1. Configurer l'action Slack
echo "1. Configuration de l'action Slack..."
response=$(curl -s -X POST "$KIBANA_URL/api/actions/action" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -u "$KIBANA_USER:$KIBANA_PASSWORD" \
    -d '{
        "name": "slack",
        "actionTypeId": ".slack",
        "config": {
            "webhookUrl": "'"$SLACK_WEBHOOK_URL"'"
        }
    }')

if [[ $response == *"\"id\":"* ]]; then
    echo "✓ Action Slack configurée"
else
    echo "✗ Échec de la configuration de l'action Slack: $response"
    exit 1
fi

# 2. Créer les alertes
echo "2. Création des alertes..."

# Alerte pour les erreurs
create_alert "Erreurs critiques" "level: ERROR OR level: FATAL" 5

# Alerte pour les erreurs d'authentification
create_alert "Erreurs d'authentification" "message: *authentication failed*" 3

# Alerte pour les erreurs de base de données
create_alert "Erreurs de base de données" "message: *database error*" 2

# 3. Vérifier les alertes
echo "3. Vérification des alertes..."
curl -s -X GET "$KIBANA_URL/api/alerting/rules/_find" \
     -H "kbn-xsrf: true" \
     -u "$KIBANA_USER:$KIBANA_PASSWORD"

echo "Configuration des alertes terminée!" 
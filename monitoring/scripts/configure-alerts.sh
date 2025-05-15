#!/bin/bash

# Configuration des variables
KIBANA_URL="http://localhost:5601"
KIBANA_USER="kibana"
KIBANA_PASSWORD="${KIBANA_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer une alerte
create_alert() {
    local name=$1
    local description=$2
    local index=$3
    local query=$4
    local threshold=$5
    local interval=$6

    echo "Création de l'alerte: $name..."
    
    # Vérifier si l'alerte existe déjà
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/alerting/rules/_find?search_fields=name&search=$name" | grep -q "\"total\":0"; then
        # Créer l'alerte
        curl -s -X POST -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/alerting/rule" \
            -d "{
                \"name\": \"$name\",
                \"description\": \"$description\",
                \"consumer\": \"alerts\",
                \"rule_type_id\": \"threshold\",
                \"schedule\": {
                    \"interval\": \"$interval\"
                },
                \"params\": {
                    \"index\": \"$index\",
                    \"timeField\": \"@timestamp\",
                    \"aggType\": \"count\",
                    \"groupBy\": \"all\",
                    \"termSize\": 5,
                    \"thresholdComparator\": \">\",
                    \"threshold\": [$threshold],
                    \"timeWindowSize\": 5,
                    \"timeWindowUnit\": \"m\"
                },
                \"actions\": [
                    {
                        \"group\": \"default\",
                        \"id\": \"default-email\",
                        \"params\": {
                            \"to\": \"admin@example.com\",
                            \"subject\": \"Alerte: $name\",
                            \"body\": \"L'alerte $name a été déclenchée. Description: $description\"
                        }
                    }
                ]
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Alerte $name créée avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création de l'alerte $name"
            return 1
        fi
    else
        echo "! Alerte $name existe déjà, mise à jour..."
        # Mettre à jour l'alerte
        curl -s -X PUT -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/alerting/rule" \
            -d "{
                \"name\": \"$name\",
                \"description\": \"$description\",
                \"consumer\": \"alerts\",
                \"rule_type_id\": \"threshold\",
                \"schedule\": {
                    \"interval\": \"$interval\"
                },
                \"params\": {
                    \"index\": \"$index\",
                    \"timeField\": \"@timestamp\",
                    \"aggType\": \"count\",
                    \"groupBy\": \"all\",
                    \"termSize\": 5,
                    \"thresholdComparator\": \">\",
                    \"threshold\": [$threshold],
                    \"timeWindowSize\": 5,
                    \"timeWindowUnit\": \"m\"
                },
                \"actions\": [
                    {
                        \"group\": \"default\",
                        \"id\": \"default-email\",
                        \"params\": {
                            \"to\": \"admin@example.com\",
                            \"subject\": \"Alerte: $name\",
                            \"body\": \"L'alerte $name a été déclenchée. Description: $description\"
                        }
                    }
                ]
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Alerte $name mise à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour de l'alerte $name"
            return 1
        fi
    fi
}

# 1. Attendre que Kibana soit prêt
echo "1. Attente de Kibana..."
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/status" > /dev/null; then
        echo "Kibana est prêt!"
        break
    fi
    if [ $i -eq $MAX_RETRIES ]; then
        echo "✗ Timeout: Kibana n'est pas prêt"
        exit 1
    fi
    echo "Tentative $i/$MAX_RETRIES..."
    sleep $RETRY_INTERVAL
done

# 2. Créer les alertes
echo "2. Création des alertes..."

# Alerte pour les erreurs système
create_alert "system-errors" "Détection d'erreurs système" "filebeat-*" "level: ERROR" 10 "1m"

# Alerte pour les erreurs d'application
create_alert "application-errors" "Détection d'erreurs d'application" "application-*" "level: ERROR" 5 "1m"

# Alerte pour les événements de sécurité
create_alert "security-events" "Détection d'événements de sécurité" "security-*" "severity: HIGH" 3 "1m"

# Alerte pour l'utilisation CPU
create_alert "cpu-usage" "Utilisation CPU élevée" "metrics-*" "metric_name: cpu_usage AND metric_value > 80" 80 "5m"

# Alerte pour l'utilisation mémoire
create_alert "memory-usage" "Utilisation mémoire élevée" "metrics-*" "metric_name: memory_usage AND metric_value > 90" 90 "5m"

# 3. Vérification
echo "3. Vérification des alertes..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/alerting/rules/_find" | grep -q "\"total\":5"; then
    echo "✓ Toutes les alertes sont configurées"
else
    echo "✗ Erreur: Certaines alertes sont manquantes"
    exit 1
fi

echo "=== Configuration des alertes terminée ===" 
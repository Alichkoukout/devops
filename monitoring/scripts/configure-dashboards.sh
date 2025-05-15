#!/bin/bash

# Configuration des variables
KIBANA_URL="http://localhost:5601"
KIBANA_USER="kibana"
KIBANA_PASSWORD="${KIBANA_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer un dashboard
create_dashboard() {
    local name=$1
    local description=$2
    local panels=$3

    echo "Création du dashboard: $name..."
    
    # Vérifier si le dashboard existe déjà
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=dashboard&search_fields=title&search=$name" | grep -q "\"total\":0"; then
        # Créer le dashboard
        curl -s -X POST -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/dashboard/$name" \
            -d "{
                \"attributes\": {
                    \"title\": \"$name\",
                    \"hits\": 0,
                    \"description\": \"$description\",
                    \"panelsJSON\": \"$panels\",
                    \"optionsJSON\": \"{\\\"hidePanelTitles\\\":false,\\\"useMargins\\\":true}\",
                    \"version\": 1,
                    \"timeRestore\": false,
                    \"kibanaSavedObjectMeta\": {
                        \"searchSourceJSON\": \"{\\\"query\\\":{\\\"query\\\":\\\"\\\",\\\"language\\\":\\\"lucene\\\"},\\\"filter\\\":[]}\"
                    }
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Dashboard $name créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création du dashboard $name"
            return 1
        fi
    else
        echo "! Dashboard $name existe déjà, mise à jour..."
        # Mettre à jour le dashboard
        curl -s -X PUT -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/dashboard/$name" \
            -d "{
                \"attributes\": {
                    \"title\": \"$name\",
                    \"hits\": 0,
                    \"description\": \"$description\",
                    \"panelsJSON\": \"$panels\",
                    \"optionsJSON\": \"{\\\"hidePanelTitles\\\":false,\\\"useMargins\\\":true}\",
                    \"version\": 1,
                    \"timeRestore\": false,
                    \"kibanaSavedObjectMeta\": {
                        \"searchSourceJSON\": \"{\\\"query\\\":{\\\"query\\\":\\\"\\\",\\\"language\\\":\\\"lucene\\\"},\\\"filter\\\":[]}\"
                    }
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Dashboard $name mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour du dashboard $name"
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

# 2. Créer les dashboards
echo "2. Création des dashboards..."

# Dashboard pour les métriques système
create_dashboard "System Overview" "Vue d'ensemble des métriques système" '[
    {
        "type": "visualization",
        "id": "system-metrics",
        "title": "Métriques système",
        "gridData": {"x": 0, "y": 0, "w": 24, "h": 15, "i": "1"}
    },
    {
        "type": "visualization",
        "id": "system-logs",
        "title": "Logs système",
        "gridData": {"x": 0, "y": 15, "w": 24, "h": 15, "i": "2"}
    }
]'

# Dashboard pour les métriques d'application
create_dashboard "Application Monitoring" "Surveillance des applications" '[
    {
        "type": "visualization",
        "id": "application-metrics",
        "title": "Métriques d'application",
        "gridData": {"x": 0, "y": 0, "w": 24, "h": 15, "i": "1"}
    },
    {
        "type": "visualization",
        "id": "application-logs",
        "title": "Logs d'application",
        "gridData": {"x": 0, "y": 15, "w": 24, "h": 15, "i": "2"}
    }
]'

# Dashboard pour les événements de sécurité
create_dashboard "Security Overview" "Vue d'ensemble de la sécurité" '[
    {
        "type": "visualization",
        "id": "security-events",
        "title": "Événements de sécurité",
        "gridData": {"x": 0, "y": 0, "w": 24, "h": 15, "i": "1"}
    },
    {
        "type": "visualization",
        "id": "security-alerts",
        "title": "Alertes de sécurité",
        "gridData": {"x": 0, "y": 15, "w": 24, "h": 15, "i": "2"}
    }
]'

# Dashboard pour les métriques de performance
create_dashboard "Performance Monitoring" "Surveillance des performances" '[
    {
        "type": "visualization",
        "id": "performance-metrics",
        "title": "Métriques de performance",
        "gridData": {"x": 0, "y": 0, "w": 24, "h": 15, "i": "1"}
    },
    {
        "type": "visualization",
        "id": "performance-logs",
        "title": "Logs de performance",
        "gridData": {"x": 0, "y": 15, "w": 24, "h": 15, "i": "2"}
    }
]'

# Dashboard pour le suivi des erreurs
create_dashboard "Error Tracking" "Suivi des erreurs" '[
    {
        "type": "visualization",
        "id": "error-metrics",
        "title": "Métriques d'erreur",
        "gridData": {"x": 0, "y": 0, "w": 24, "h": 15, "i": "1"}
    },
    {
        "type": "visualization",
        "id": "error-logs",
        "title": "Logs d'erreur",
        "gridData": {"x": 0, "y": 15, "w": 24, "h": 15, "i": "2"}
    }
]'

# 3. Vérification
echo "3. Vérification des dashboards..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=dashboard" | grep -q "\"total\":5"; then
    echo "✓ Tous les dashboards sont configurés"
else
    echo "✗ Erreur: Certains dashboards sont manquants"
    exit 1
fi

echo "=== Configuration des dashboards terminée ===" 
#!/bin/bash

# Configuration des variables
KIBANA_URL="http://localhost:5601"
KIBANA_USER="kibana"
KIBANA_PASSWORD="${KIBANA_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer un index pattern
create_index_pattern() {
    local name=$1
    local pattern=$2
    local time_field=$3

    echo "Création de l'index pattern: $name..."
    
    # Vérifier si l'index pattern existe déjà
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=index-pattern&search_fields=title&search=$name" | grep -q "\"total\":0"; then
        # Créer l'index pattern
        curl -s -X POST -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/index-pattern/$name" \
            -d "{
                \"attributes\": {
                    \"title\": \"$pattern\",
                    \"timeFieldName\": \"$time_field\"
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Index pattern $name créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création de l'index pattern $name"
            return 1
        fi
    else
        echo "! Index pattern $name existe déjà, mise à jour..."
        # Mettre à jour l'index pattern
        curl -s -X PUT -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/index-pattern/$name" \
            -d "{
                \"attributes\": {
                    \"title\": \"$pattern\",
                    \"timeFieldName\": \"$time_field\"
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Index pattern $name mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour de l'index pattern $name"
            return 1
        fi
    fi
}

# Fonction pour définir l'index pattern par défaut
set_default_index_pattern() {
    local pattern=$1

    echo "Définition de l'index pattern par défaut: $pattern..."
    
    curl -s -X POST -u "$KIBANA_USER:$KIBANA_PASSWORD" \
        -H "kbn-xsrf: true" \
        -H "Content-Type: application/json" \
        "$KIBANA_URL/api/kibana/settings/defaultIndex" \
        -d "{
            \"value\": \"$pattern\"
        }"
    
    if [ $? -eq 0 ]; then
        echo "✓ Index pattern par défaut défini avec succès"
        return 0
    else
        echo "✗ Erreur lors de la définition de l'index pattern par défaut"
        return 1
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

# 2. Créer les index patterns
echo "2. Création des index patterns..."

# Index pattern pour les logs système
create_index_pattern "system-logs" "filebeat-*" "@timestamp"

# Index pattern pour les logs d'application
create_index_pattern "application-logs" "application-*" "@timestamp"

# Index pattern pour les logs de sécurité
create_index_pattern "security-logs" "security-*" "@timestamp"

# Index pattern pour les métriques
create_index_pattern "metrics" "metrics-*" "@timestamp"

# Index pattern pour les logs d'erreur
create_index_pattern "error-logs" "error-*" "@timestamp"

# 3. Définir l'index pattern par défaut
set_default_index_pattern "filebeat-*"

# 4. Vérification
echo "4. Vérification des index patterns..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=index-pattern" | grep -q "\"total\":5"; then
    echo "✓ Tous les index patterns sont configurés"
else
    echo "✗ Erreur: Certains index patterns sont manquants"
    exit 1
fi

echo "=== Configuration des index patterns terminée ===" 
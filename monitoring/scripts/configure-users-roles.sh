#!/bin/bash

# Configuration des variables
ES_URL="http://localhost:9200"
ES_USER="elastic"
ES_PASSWORD="${ELASTIC_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer un rôle
create_role() {
    local name=$1
    local privileges=$2

    echo "Création du rôle: $name..."
    
    # Vérifier si le rôle existe déjà
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/role/$name" | grep -q "\"error\""; then
        # Créer le rôle
        curl -s -X POST -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/role/$name" \
            -d "$privileges"
        
        if [ $? -eq 0 ]; then
            echo "✓ Rôle $name créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création du rôle $name"
            return 1
        fi
    else
        echo "! Rôle $name existe déjà, mise à jour..."
        # Mettre à jour le rôle
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/role/$name" \
            -d "$privileges"
        
        if [ $? -eq 0 ]; then
            echo "✓ Rôle $name mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour du rôle $name"
            return 1
        fi
    fi
}

# Fonction pour créer un utilisateur
create_user() {
    local username=$1
    local password=$2
    local roles=$3

    echo "Création de l'utilisateur: $username..."
    
    # Vérifier si l'utilisateur existe déjà
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/user/$username" | grep -q "\"error\""; then
        # Créer l'utilisateur
        curl -s -X POST -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/user/$username" \
            -d "{
                \"password\": \"$password\",
                \"roles\": $roles,
                \"full_name\": \"$username\",
                \"email\": \"$username@example.com\",
                \"metadata\": {
                    \"intelligence\": 7
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Utilisateur $username créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création de l'utilisateur $username"
            return 1
        fi
    else
        echo "! Utilisateur $username existe déjà, mise à jour..."
        # Mettre à jour l'utilisateur
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/user/$username" \
            -d "{
                \"password\": \"$password\",
                \"roles\": $roles,
                \"full_name\": \"$username\",
                \"email\": \"$username@example.com\",
                \"metadata\": {
                    \"intelligence\": 7
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Utilisateur $username mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour de l'utilisateur $username"
            return 1
        fi
    fi
}

# 1. Attendre qu'Elasticsearch soit prêt
echo "1. Attente d'Elasticsearch..."
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_cluster/health" > /dev/null; then
        echo "Elasticsearch est prêt!"
        break
    fi
    if [ $i -eq $MAX_RETRIES ]; then
        echo "✗ Timeout: Elasticsearch n'est pas prêt"
        exit 1
    fi
    echo "Tentative $i/$MAX_RETRIES..."
    sleep $RETRY_INTERVAL
done

# 2. Créer les rôles
echo "2. Création des rôles..."

# Rôle pour les administrateurs
create_role "admin" '{
    "cluster": ["all"],
    "indices": [
        {
            "names": ["*"],
            "privileges": ["all"]
        }
    ],
    "applications": [
        {
            "application": "kibana-.kibana",
            "privileges": ["all"],
            "resources": ["*"]
        }
    ]
}'

# Rôle pour les utilisateurs de monitoring
create_role "monitoring_user" '{
    "cluster": ["monitor"],
    "indices": [
        {
            "names": ["filebeat-*", "application-*", "security-*", "metrics-*", "error-*"],
            "privileges": ["read", "view_index_metadata"]
        }
    ],
    "applications": [
        {
            "application": "kibana-.kibana",
            "privileges": ["read"],
            "resources": ["*"]
        }
    ]
}'

# Rôle pour les utilisateurs de logs
create_role "log_user" '{
    "cluster": ["monitor"],
    "indices": [
        {
            "names": ["filebeat-*", "application-*", "error-*"],
            "privileges": ["read", "view_index_metadata"]
        }
    ],
    "applications": [
        {
            "application": "kibana-.kibana",
            "privileges": ["read"],
            "resources": ["*"]
        }
    ]
}'

# Rôle pour les utilisateurs de sécurité
create_role "security_user" '{
    "cluster": ["monitor"],
    "indices": [
        {
            "names": ["security-*"],
            "privileges": ["read", "view_index_metadata"]
        }
    ],
    "applications": [
        {
            "application": "kibana-.kibana",
            "privileges": ["read"],
            "resources": ["*"]
        }
    ]
}'

# 3. Créer les utilisateurs
echo "3. Création des utilisateurs..."

# Utilisateur administrateur
create_user "admin" "${ELASTIC_PASSWORD}" '["admin"]'

# Utilisateur monitoring
create_user "monitoring" "${KIBANA_PASSWORD}" '["monitoring_user"]'

# Utilisateur logs
create_user "logs" "${LOGSTASH_PASSWORD}" '["log_user"]'

# Utilisateur sécurité
create_user "security" "${FILEBEAT_PASSWORD}" '["security_user"]'

# 4. Vérification
echo "4. Vérification des rôles et utilisateurs..."
if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/role" | grep -q "\"total\":4" && \
   curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/user" | grep -q "\"total\":4"; then
    echo "✓ Tous les rôles et utilisateurs sont configurés"
else
    echo "✗ Erreur: Certains rôles ou utilisateurs sont manquants"
    exit 1
fi

echo "=== Configuration des utilisateurs et rôles terminée ===" 
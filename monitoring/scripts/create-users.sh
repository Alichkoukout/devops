#!/bin/bash

# Vérifier si le mode production est activé
if [ "$1" = "production" ]; then
    ELASTIC_PASSWORD="production_elastic_password"
    KIBANA_PASSWORD="production_kibana_password"
    LOGSTASH_PASSWORD="production_logstash_password"
    FILEBEAT_PASSWORD="production_filebeat_password"
else
    ELASTIC_PASSWORD="changeme"
    KIBANA_PASSWORD="changeme"
    LOGSTASH_PASSWORD="changeme"
    FILEBEAT_PASSWORD="changeme"
fi

# Configuration des variables
ES_URL="http://localhost:9200"
ES_USER="elastic"
ES_PASSWORD="${ELASTIC_PASSWORD}"
CERT_DIR="/opt/monitoring/certs"

# Fonction pour créer un utilisateur
create_user() {
    local username=$1
    local password=$2
    local roles=$3

    echo "Création de l'utilisateur: $username..."
    
    # Vérifier si l'utilisateur existe déjà
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/user/$username" | grep -q "\"found\":true"; then
        echo "! Utilisateur $username existe déjà, mise à jour..."
        # Mettre à jour l'utilisateur
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/user/$username" \
            -d "{
                \"password\": \"$password\",
                \"roles\": $roles,
                \"full_name\": \"$username\",
                \"email\": \"$username@example.com\"
            }"
    else
        # Créer l'utilisateur
        curl -s -X POST -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/user/$username" \
            -d "{
                \"password\": \"$password\",
                \"roles\": $roles,
                \"full_name\": \"$username\",
                \"email\": \"$username@example.com\"
            }"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ Utilisateur $username créé/mis à jour avec succès"
        return 0
    else
        echo "✗ Erreur lors de la création/mise à jour de l'utilisateur $username"
        return 1
    fi
}

# Fonction pour créer un rôle
create_role() {
    local name=$1
    local privileges=$2

    echo "Création du rôle: $name..."
    
    # Vérifier si le rôle existe déjà
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/role/$name" | grep -q "\"found\":true"; then
        echo "! Rôle $name existe déjà, mise à jour..."
        # Mettre à jour le rôle
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/role/$name" \
            -d "$privileges"
    else
        # Créer le rôle
        curl -s -X POST -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_security/role/$name" \
            -d "$privileges"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ Rôle $name créé/mis à jour avec succès"
        return 0
    else
        echo "✗ Erreur lors de la création/mise à jour du rôle $name"
        return 1
    fi
}

# 1. Attendre qu'Elasticsearch soit prêt
echo "1. Attente d'Elasticsearch..."
for i in $(seq 1 30); do
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_cluster/health" > /dev/null; then
        echo "Elasticsearch est prêt!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ Timeout: Elasticsearch n'est pas prêt"
        exit 1
    fi
    echo "Tentative $i/30..."
    sleep 10
done

# 2. Créer les rôles
echo "2. Création des rôles..."

# Rôle pour Kibana
create_role "kibana_user" '{
    "cluster": ["monitor"],
    "indices": [
        {
            "names": ["kibana-*"],
            "privileges": ["all"]
        },
        {
            "names": ["filebeat-*", "logstash-*", "application-*"],
            "privileges": ["read", "view_index_metadata"]
        }
    ]
}'

# Rôle pour Logstash
create_role "logstash_writer" '{
    "cluster": ["monitor"],
    "indices": [
        {
            "names": ["filebeat-*", "logstash-*", "application-*"],
            "privileges": ["create_index", "index", "write", "delete", "manage"]
        }
    ]
}'

# Rôle pour Filebeat
create_role "filebeat_writer" '{
    "cluster": ["monitor"],
    "indices": [
        {
            "names": ["filebeat-*"],
            "privileges": ["create_index", "index", "write"]
        }
    ]
}'

# 3. Créer les utilisateurs
echo "3. Création des utilisateurs..."

# Utilisateur Kibana
create_user "kibana" "${KIBANA_PASSWORD}" '["kibana_user"]'

# Utilisateur Logstash
create_user "logstash" "${LOGSTASH_PASSWORD}" '["logstash_writer"]'

# Utilisateur Filebeat
create_user "filebeat" "${FILEBEAT_PASSWORD}" '["filebeat_writer"]'

# 4. Vérification
echo "4. Vérification des utilisateurs et rôles..."

# Vérifier les rôles
echo "Rôles configurés:"
curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/role" | jq '.'

# Vérifier les utilisateurs
echo "Utilisateurs configurés:"
curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_security/user" | jq '.'

echo "=== Création des utilisateurs terminée ===" 
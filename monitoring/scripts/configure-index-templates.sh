#!/bin/bash

# Configuration des variables
ES_URL="http://localhost:9200"
ES_USER="elastic"
ES_PASSWORD="${ELASTIC_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer un template d'index
create_index_template() {
    local name=$1
    local pattern=$2
    local template=$3

    echo "Création du template d'index: $name..."
    
    # Vérifier si le template existe déjà
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_index_template/$name" | grep -q "\"error\""; then
        # Créer le template
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_index_template/$name" \
            -d "{
                \"index_patterns\": [\"$pattern\"],
                \"template\": $template,
                \"priority\": 100,
                \"composed_of\": [],
                \"version\": 1,
                \"_meta\": {
                    \"description\": \"Template pour $name\"
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Template $name créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création du template $name"
            return 1
        fi
    else
        echo "! Template $name existe déjà, mise à jour..."
        # Mettre à jour le template
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_index_template/$name" \
            -d "{
                \"index_patterns\": [\"$pattern\"],
                \"template\": $template,
                \"priority\": 100,
                \"composed_of\": [],
                \"version\": 1,
                \"_meta\": {
                    \"description\": \"Template pour $name\"
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Template $name mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour du template $name"
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

# 2. Créer les templates d'index
echo "2. Création des templates d'index..."

# Template pour les logs système
create_index_template "system-logs" "filebeat-*" '{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
    },
    "mappings": {
        "properties": {
            "@timestamp": {
                "type": "date"
            },
            "message": {
                "type": "text"
            },
            "host": {
                "type": "keyword"
            },
            "level": {
                "type": "keyword"
            },
            "service": {
                "type": "keyword"
            }
        }
    }
}'

# Template pour les logs d'application
create_index_template "application-logs" "application-*" '{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
    },
    "mappings": {
        "properties": {
            "@timestamp": {
                "type": "date"
            },
            "message": {
                "type": "text"
            },
            "application": {
                "type": "keyword"
            },
            "level": {
                "type": "keyword"
            },
            "trace_id": {
                "type": "keyword"
            }
        }
    }
}'

# Template pour les logs de sécurité
create_index_template "security-logs" "security-*" '{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
    },
    "mappings": {
        "properties": {
            "@timestamp": {
                "type": "date"
            },
            "message": {
                "type": "text"
            },
            "event_type": {
                "type": "keyword"
            },
            "severity": {
                "type": "keyword"
            },
            "source_ip": {
                "type": "ip"
            }
        }
    }
}'

# Template pour les métriques
create_index_template "metrics" "metrics-*" '{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
    },
    "mappings": {
        "properties": {
            "@timestamp": {
                "type": "date"
            },
            "metric_name": {
                "type": "keyword"
            },
            "metric_value": {
                "type": "float"
            },
            "host": {
                "type": "keyword"
            }
        }
    }
}'

# Template pour les logs d'erreur
create_index_template "error-logs" "error-*" '{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
    },
    "mappings": {
        "properties": {
            "@timestamp": {
                "type": "date"
            },
            "message": {
                "type": "text"
            },
            "error_type": {
                "type": "keyword"
            },
            "stack_trace": {
                "type": "text"
            },
            "service": {
                "type": "keyword"
            }
        }
    }
}'

# 3. Vérification
echo "3. Vérification des templates d'index..."
if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_index_template" | grep -q "\"total\":5"; then
    echo "✓ Tous les templates d'index sont configurés"
else
    echo "✗ Erreur: Certains templates d'index sont manquants"
    exit 1
fi

echo "=== Configuration des templates d'index terminée ===" 
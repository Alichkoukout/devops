#!/bin/bash

# Configuration des variables
ES_URL="http://localhost:9200"
ES_USER="elastic"
ES_PASSWORD="${ELASTIC_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer une politique de rétention
create_retention_policy() {
    local name=$1
    local pattern=$2
    local policy=$3

    echo "Création de la politique de rétention: $name..."
    
    # Vérifier si la politique existe déjà
    if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_ilm/policy/$name" | grep -q "\"error\""; then
        # Créer la politique
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_ilm/policy/$name" \
            -d "$policy"
        
        if [ $? -eq 0 ]; then
            echo "✓ Politique $name créée avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création de la politique $name"
            return 1
        fi
    else
        echo "! Politique $name existe déjà, mise à jour..."
        # Mettre à jour la politique
        curl -s -X PUT -u "$ES_USER:$ES_PASSWORD" \
            -H "Content-Type: application/json" \
            "$ES_URL/_ilm/policy/$name" \
            -d "$policy"
        
        if [ $? -eq 0 ]; then
            echo "✓ Politique $name mise à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour de la politique $name"
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

# 2. Créer les politiques de rétention
echo "2. Création des politiques de rétention..."

# Politique pour les logs système
create_retention_policy "system-logs-policy" "filebeat-*" '{
    "policy": {
        "phases": {
            "hot": {
                "min_age": "0ms",
                "actions": {
                    "rollover": {
                        "max_age": "7d",
                        "max_size": "50gb"
                    }
                }
            },
            "delete": {
                "min_age": "30d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}'

# Politique pour les logs d'application
create_retention_policy "application-logs-policy" "application-*" '{
    "policy": {
        "phases": {
            "hot": {
                "min_age": "0ms",
                "actions": {
                    "rollover": {
                        "max_age": "7d",
                        "max_size": "50gb"
                    }
                }
            },
            "delete": {
                "min_age": "30d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}'

# Politique pour les logs de sécurité
create_retention_policy "security-logs-policy" "security-*" '{
    "policy": {
        "phases": {
            "hot": {
                "min_age": "0ms",
                "actions": {
                    "rollover": {
                        "max_age": "7d",
                        "max_size": "50gb"
                    }
                }
            },
            "delete": {
                "min_age": "90d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}'

# Politique pour les métriques
create_retention_policy "metrics-policy" "metrics-*" '{
    "policy": {
        "phases": {
            "hot": {
                "min_age": "0ms",
                "actions": {
                    "rollover": {
                        "max_age": "7d",
                        "max_size": "50gb"
                    }
                }
            },
            "delete": {
                "min_age": "30d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}'

# Politique pour les logs d'erreur
create_retention_policy "error-logs-policy" "error-*" '{
    "policy": {
        "phases": {
            "hot": {
                "min_age": "0ms",
                "actions": {
                    "rollover": {
                        "max_age": "7d",
                        "max_size": "50gb"
                    }
                }
            },
            "delete": {
                "min_age": "30d",
                "actions": {
                    "delete": {}
                }
            }
        }
    }
}'

# 3. Vérification
echo "3. Vérification des politiques de rétention..."
if curl -s -u "$ES_USER:$ES_PASSWORD" "$ES_URL/_ilm/policy" | grep -q "\"total\":5"; then
    echo "✓ Toutes les politiques de rétention sont configurées"
else
    echo "✗ Erreur: Certaines politiques de rétention sont manquantes"
    exit 1
fi

echo "=== Configuration des politiques de rétention terminée ===" 
#!/bin/bash

# Configuration des variables
LOGSTASH_URL="http://localhost:9600"
LOGSTASH_USER="logstash"
LOGSTASH_PASSWORD="${LOGSTASH_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer un pipeline
create_pipeline() {
    local name=$1
    local config=$2

    echo "Création du pipeline: $name..."
    
    # Vérifier si le pipeline existe déjà
    if curl -s -u "$LOGSTASH_USER:$LOGSTASH_PASSWORD" "$LOGSTASH_URL/_node/pipelines/$name" | grep -q "\"error\""; then
        # Créer le pipeline
        curl -s -X PUT -u "$LOGSTASH_USER:$LOGSTASH_PASSWORD" \
            -H "Content-Type: application/json" \
            "$LOGSTASH_URL/_node/pipelines/$name" \
            -d "$config"
        
        if [ $? -eq 0 ]; then
            echo "✓ Pipeline $name créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création du pipeline $name"
            return 1
        fi
    else
        echo "! Pipeline $name existe déjà, mise à jour..."
        # Mettre à jour le pipeline
        curl -s -X PUT -u "$LOGSTASH_USER:$LOGSTASH_PASSWORD" \
            -H "Content-Type: application/json" \
            "$LOGSTASH_URL/_node/pipelines/$name" \
            -d "$config"
        
        if [ $? -eq 0 ]; then
            echo "✓ Pipeline $name mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour du pipeline $name"
            return 1
        fi
    fi
}

# 1. Attendre que Logstash soit prêt
echo "1. Attente de Logstash..."
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s -u "$LOGSTASH_USER:$LOGSTASH_PASSWORD" "$LOGSTASH_URL/_node/stats" > /dev/null; then
        echo "Logstash est prêt!"
        break
    fi
    if [ $i -eq $MAX_RETRIES ]; then
        echo "✗ Timeout: Logstash n'est pas prêt"
        exit 1
    fi
    echo "Tentative $i/$MAX_RETRIES..."
    sleep $RETRY_INTERVAL
done

# 2. Créer les pipelines
echo "2. Création des pipelines..."

# Pipeline pour les logs système
create_pipeline "system-logs" '{
    "pipeline": {
        "workers": 1,
        "batch_size": 125,
        "batch_delay": 50,
        "config": {
            "input": {
                "beats": {
                    "port": 5044,
                    "ssl": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key"
                }
            },
            "filter": {
                "grok": {
                    "match": {
                        "message": "%{SYSLOGBASE} %{GREEDYDATA:syslog_message}"
                    }
                }
            },
            "output": {
                "elasticsearch": {
                    "hosts": ["localhost:9200"],
                    "index": "filebeat-%{+YYYY.MM.dd}",
                    "ssl": true,
                    "ssl_certificate_verification": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key",
                    "user": "logstash",
                    "password": "'${LOGSTASH_PASSWORD}'"
                }
            }
        }
    }
}'

# Pipeline pour les logs d'application
create_pipeline "application-logs" '{
    "pipeline": {
        "workers": 1,
        "batch_size": 125,
        "batch_delay": 50,
        "config": {
            "input": {
                "beats": {
                    "port": 5045,
                    "ssl": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key"
                }
            },
            "filter": {
                "grok": {
                    "match": {
                        "message": "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}"
                    }
                }
            },
            "output": {
                "elasticsearch": {
                    "hosts": ["localhost:9200"],
                    "index": "application-%{+YYYY.MM.dd}",
                    "ssl": true,
                    "ssl_certificate_verification": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key",
                    "user": "logstash",
                    "password": "'${LOGSTASH_PASSWORD}'"
                }
            }
        }
    }
}'

# Pipeline pour les logs de sécurité
create_pipeline "security-logs" '{
    "pipeline": {
        "workers": 1,
        "batch_size": 125,
        "batch_delay": 50,
        "config": {
            "input": {
                "beats": {
                    "port": 5046,
                    "ssl": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key"
                }
            },
            "filter": {
                "grok": {
                    "match": {
                        "message": "%{SECURITY}"
                    }
                }
            },
            "output": {
                "elasticsearch": {
                    "hosts": ["localhost:9200"],
                    "index": "security-%{+YYYY.MM.dd}",
                    "ssl": true,
                    "ssl_certificate_verification": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key",
                    "user": "logstash",
                    "password": "'${LOGSTASH_PASSWORD}'"
                }
            }
        }
    }
}'

# Pipeline pour les métriques
create_pipeline "metrics" '{
    "pipeline": {
        "workers": 1,
        "batch_size": 125,
        "batch_delay": 50,
        "config": {
            "input": {
                "beats": {
                    "port": 5047,
                    "ssl": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key"
                }
            },
            "filter": {
                "grok": {
                    "match": {
                        "message": "%{METRICS}"
                    }
                }
            },
            "output": {
                "elasticsearch": {
                    "hosts": ["localhost:9200"],
                    "index": "metrics-%{+YYYY.MM.dd}",
                    "ssl": true,
                    "ssl_certificate_verification": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key",
                    "user": "logstash",
                    "password": "'${LOGSTASH_PASSWORD}'"
                }
            }
        }
    }
}'

# Pipeline pour les logs d'erreur
create_pipeline "error-logs" '{
    "pipeline": {
        "workers": 1,
        "batch_size": 125,
        "batch_delay": 50,
        "config": {
            "input": {
                "beats": {
                    "port": 5048,
                    "ssl": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key"
                }
            },
            "filter": {
                "grok": {
                    "match": {
                        "message": "%{ERROR}"
                    }
                }
            },
            "output": {
                "elasticsearch": {
                    "hosts": ["localhost:9200"],
                    "index": "error-%{+YYYY.MM.dd}",
                    "ssl": true,
                    "ssl_certificate_verification": true,
                    "ssl_certificate": "/etc/logstash/certs/logstash.crt",
                    "ssl_key": "/etc/logstash/certs/logstash.key",
                    "user": "logstash",
                    "password": "'${LOGSTASH_PASSWORD}'"
                }
            }
        }
    }
}'

# 3. Vérification
echo "3. Vérification des pipelines..."
if curl -s -u "$LOGSTASH_USER:$LOGSTASH_PASSWORD" "$LOGSTASH_URL/_node/pipelines" | grep -q "\"total\":5"; then
    echo "✓ Tous les pipelines sont configurés"
else
    echo "✗ Erreur: Certains pipelines sont manquants"
    exit 1
fi

echo "=== Configuration des pipelines Logstash terminée ===" 
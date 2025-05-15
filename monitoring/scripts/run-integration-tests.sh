#!/bin/bash

# Configuration
ES_URL="http://test-elasticsearch:9200"
KIBANA_URL="http://test-kibana:5601"
LOGSTASH_URL="http://test-logstash:9600"
PROMETHEUS_URL="http://test-prometheus:9090"
GRAFANA_URL="http://test-grafana:3000"

# Fonction pour tester l'intégration Elasticsearch-Logstash
test_es_logstash_integration() {
    echo "Testing Elasticsearch-Logstash integration..."
    
    # Créer un index de test
    curl -X PUT "$ES_URL/test-index" -H "Content-Type: application/json" -d '{
        "mappings": {
            "properties": {
                "message": { "type": "text" },
                "@timestamp": { "type": "date" }
            }
        }
    }' --connect-timeout 30
    
    # Envoyer un log via Logstash
    echo '{"message": "Test log", "@timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}' | \
    nc test-logstash 5044
    
    # Vérifier que le log est indexé
    sleep 5
    response=$(curl -s --connect-timeout 30 "$ES_URL/test-index/_search?q=message:Test+log")
    if echo "$response" | grep -q "Test log"; then
        echo "✅ Elasticsearch-Logstash integration test passed"
        return 0
    else
        echo "❌ Elasticsearch-Logstash integration test failed"
        return 1
    fi
}

# Fonction pour tester l'intégration Kibana-Elasticsearch
test_kibana_es_integration() {
    echo "Testing Kibana-Elasticsearch integration..."
    
    # Créer un index pattern
    curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/test-pattern" \
        -H "kbn-xsrf: true" \
        -H "Content-Type: application/json" \
        -d '{
            "attributes": {
                "title": "test-*",
                "timeFieldName": "@timestamp"
            }
        }' --connect-timeout 30
    
    # Vérifier que l'index pattern est créé
    response=$(curl -s --connect-timeout 30 "$KIBANA_URL/api/saved_objects/_find?type=index-pattern")
    if echo "$response" | grep -q "test-pattern"; then
        echo "✅ Kibana-Elasticsearch integration test passed"
        return 0
    else
        echo "❌ Kibana-Elasticsearch integration test failed"
        return 1
    fi
}

# Fonction pour tester l'intégration Prometheus-Grafana
test_prometheus_grafana_integration() {
    echo "Testing Prometheus-Grafana integration..."
    
    # Créer une source de données Prometheus dans Grafana
    curl -X POST "$GRAFANA_URL/api/datasources" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://test-prometheus:9090",
            "access": "proxy"
        }' --connect-timeout 30
    
    # Vérifier que la source de données est créée
    response=$(curl -s --connect-timeout 30 "$GRAFANA_URL/api/datasources")
    if echo "$response" | grep -q "Prometheus"; then
        echo "✅ Prometheus-Grafana integration test passed"
        return 0
    else
        echo "❌ Prometheus-Grafana integration test failed"
        return 1
    fi
}

# Fonction pour tester l'intégration Filebeat-Logstash
test_filebeat_logstash_integration() {
    echo "Testing Filebeat-Logstash integration..."
    
    # Créer un fichier de test
    echo "Test log message" > /tmp/test.log
    
    # Configurer Filebeat pour envoyer le log
    curl -X POST "$LOGSTASH_URL/_node/pipelines" \
        -H "Content-Type: application/json" \
        -d '{
            "pipeline": {
                "id": "test-pipeline",
                "config": {
                    "input": {
                        "file": {
                            "path": "/tmp/test.log"
                        }
                    }
                }
            }
        }' --connect-timeout 30
    
    # Vérifier que le log est reçu par Logstash
    sleep 5
    response=$(curl -s --connect-timeout 30 "$LOGSTASH_URL/_node/stats")
    if echo "$response" | grep -q "test-pipeline"; then
        echo "✅ Filebeat-Logstash integration test passed"
        return 0
    else
        echo "❌ Filebeat-Logstash integration test failed"
        return 1
    fi
}

# Exécuter tous les tests d'intégration
echo "Starting integration tests..."
failed=0

test_es_logstash_integration || failed=1
test_kibana_es_integration || failed=1
test_prometheus_grafana_integration || failed=1
test_filebeat_logstash_integration || failed=1

# Nettoyage
curl -X DELETE "$ES_URL/test-index" --connect-timeout 30
curl -X DELETE "$KIBANA_URL/api/saved_objects/index-pattern/test-pattern" --connect-timeout 30
curl -X DELETE "$GRAFANA_URL/api/datasources/1" --connect-timeout 30
rm -f /tmp/test.log

# Afficher le résultat final
if [ $failed -eq 0 ]; then
    echo "✅ All integration tests passed!"
    exit 0
else
    echo "❌ Some integration tests failed!"
    exit 1
fi 
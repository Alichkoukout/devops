#!/bin/bash

# Configuration
ES_URL="http://localhost:9200"
KIBANA_URL="http://localhost:5601"
LOGSTASH_URL="http://localhost:9600"
PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3000"

# Fonction pour tester Elasticsearch
test_elasticsearch() {
    echo "Testing Elasticsearch..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $ES_URL)
    if [ "$response" == "200" ]; then
        echo "✅ Elasticsearch is running"
        return 0
    else
        echo "❌ Elasticsearch test failed"
        return 1
    fi
}

# Fonction pour tester Kibana
test_kibana() {
    echo "Testing Kibana..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $KIBANA_URL)
    if [ "$response" == "200" ]; then
        echo "✅ Kibana is running"
        return 0
    else
        echo "❌ Kibana test failed"
        return 1
    fi
}

# Fonction pour tester Logstash
test_logstash() {
    echo "Testing Logstash..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $LOGSTASH_URL)
    if [ "$response" == "200" ]; then
        echo "✅ Logstash is running"
        return 0
    else
        echo "❌ Logstash test failed"
        return 1
    fi
}

# Fonction pour tester Prometheus
test_prometheus() {
    echo "Testing Prometheus..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $PROMETHEUS_URL/-/healthy)
    if [ "$response" == "200" ]; then
        echo "✅ Prometheus is running"
        return 0
    else
        echo "❌ Prometheus test failed"
        return 1
    fi
}

# Fonction pour tester Grafana
test_grafana() {
    echo "Testing Grafana..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $GRAFANA_URL/api/health)
    if [ "$response" == "200" ]; then
        echo "✅ Grafana is running"
        return 0
    else
        echo "❌ Grafana test failed"
        return 1
    fi
}

# Fonction pour tester les index templates
test_index_templates() {
    echo "Testing index templates..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $ES_URL/_template)
    if [ "$response" == "200" ]; then
        echo "✅ Index templates are configured"
        return 0
    else
        echo "❌ Index templates test failed"
        return 1
    fi
}

# Fonction pour tester les pipelines Logstash
test_logstash_pipelines() {
    echo "Testing Logstash pipelines..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $LOGSTASH_URL/_node/pipelines)
    if [ "$response" == "200" ]; then
        echo "✅ Logstash pipelines are configured"
        return 0
    else
        echo "❌ Logstash pipelines test failed"
        return 1
    fi
}

# Fonction pour tester les dashboards Kibana
test_kibana_dashboards() {
    echo "Testing Kibana dashboards..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $KIBANA_URL/api/saved_objects/_find?type=dashboard)
    if [ "$response" == "200" ]; then
        echo "✅ Kibana dashboards are configured"
        return 0
    else
        echo "❌ Kibana dashboards test failed"
        return 1
    fi
}

# Fonction pour tester les alertes
test_alerts() {
    echo "Testing alerts..."
    response=$(curl -s -o /dev/null -w "%{http_code}" $KIBANA_URL/api/alerting/rules/_find)
    if [ "$response" == "200" ]; then
        echo "✅ Alerts are configured"
        return 0
    else
        echo "❌ Alerts test failed"
        return 1
    fi
}

# Exécuter tous les tests
echo "Starting tests..."
failed=0

test_elasticsearch || failed=1
test_kibana || failed=1
test_logstash || failed=1
test_prometheus || failed=1
test_grafana || failed=1
test_index_templates || failed=1
test_logstash_pipelines || failed=1
test_kibana_dashboards || failed=1
test_alerts || failed=1

# Afficher le résultat final
if [ $failed -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi 
#!/bin/bash

# Configuration
ES_URL="http://test-elasticsearch:9200"
KIBANA_URL="http://test-kibana:5601"
LOGSTASH_URL="http://test-logstash:9600"
PROMETHEUS_URL="http://test-prometheus:9090"
GRAFANA_URL="http://test-grafana:3000"

# Fonction pour tester les services
test_service() {
    local service=$1
    local url=$2
    local timeout=30
    local retries=3
    local count=0

    echo "Testing $service..."
    while [ $count -lt $retries ]; do
        response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $timeout $url)
        if [ "$response" == "200" ]; then
            echo "✅ $service is running"
            return 0
        fi
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            echo "Retrying $service... (Attempt $count of $retries)"
            sleep 5
        fi
    done
    echo "❌ $service test failed"
    return 1
}

# Fonction pour tester les index templates
test_index_templates() {
    echo "Testing index templates..."
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 30 $ES_URL/_template)
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
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 30 $LOGSTASH_URL/_node/pipelines)
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
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 30 $KIBANA_URL/api/saved_objects/_find?type=dashboard)
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
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 30 $KIBANA_URL/api/alerting/rules/_find)
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

test_service "Elasticsearch" $ES_URL || failed=1
test_service "Kibana" $KIBANA_URL || failed=1
test_service "Logstash" $LOGSTASH_URL || failed=1
test_service "Prometheus" $PROMETHEUS_URL || failed=1
test_service "Grafana" $GRAFANA_URL || failed=1
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
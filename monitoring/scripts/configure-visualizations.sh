#!/bin/bash

# Configuration des variables
KIBANA_URL="http://localhost:5601"
KIBANA_USER="kibana"
KIBANA_PASSWORD="${KIBANA_PASSWORD}"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer une visualisation
create_visualization() {
    local name=$1
    local type=$2
    local index=$3
    local config=$4

    echo "Création de la visualisation: $name..."
    
    # Vérifier si la visualisation existe déjà
    if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=visualization&search_fields=title&search=$name" | grep -q "\"total\":0"; then
        # Créer la visualisation
        curl -s -X POST -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/visualization/$name" \
            -d "{
                \"attributes\": {
                    \"title\": \"$name\",
                    \"visState\": \"$config\",
                    \"uiStateJSON\": \"{}\",
                    \"description\": \"\",
                    \"version\": 1,
                    \"kibanaSavedObjectMeta\": {
                        \"searchSourceJSON\": \"{\\\"index\\\":\\\"$index\\\",\\\"query\\\":{\\\"query\\\":\\\"\\\",\\\"language\\\":\\\"lucene\\\"},\\\"filter\\\":[]}\"
                    }
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Visualisation $name créée avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création de la visualisation $name"
            return 1
        fi
    else
        echo "! Visualisation $name existe déjà, mise à jour..."
        # Mettre à jour la visualisation
        curl -s -X PUT -u "$KIBANA_USER:$KIBANA_PASSWORD" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            "$KIBANA_URL/api/saved_objects/visualization/$name" \
            -d "{
                \"attributes\": {
                    \"title\": \"$name\",
                    \"visState\": \"$config\",
                    \"uiStateJSON\": \"{}\",
                    \"description\": \"\",
                    \"version\": 1,
                    \"kibanaSavedObjectMeta\": {
                        \"searchSourceJSON\": \"{\\\"index\\\":\\\"$index\\\",\\\"query\\\":{\\\"query\\\":\\\"\\\",\\\"language\\\":\\\"lucene\\\"},\\\"filter\\\":[]}\"
                    }
                }
            }"
        
        if [ $? -eq 0 ]; then
            echo "✓ Visualisation $name mise à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour de la visualisation $name"
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

# 2. Créer les visualisations
echo "2. Création des visualisations..."

# Visualisations pour les métriques système
create_visualization "system-metrics" "line" "filebeat-*" '{
    "title": "Métriques système",
    "type": "line",
    "params": {
        "type": "line",
        "grid": {"categoryLines": false},
        "categoryAxes": [{
            "id": "CategoryAxis-1",
            "type": "category",
            "position": "bottom",
            "show": true,
            "style": {},
            "scale": {"type": "linear"},
            "labels": {"show": true, "filter": true, "truncate": 100},
            "title": {}
        }],
        "valueAxes": [{
            "id": "ValueAxis-1",
            "name": "LeftAxis-1",
            "type": "value",
            "position": "left",
            "show": true,
            "style": {},
            "scale": {"type": "linear", "mode": "normal"},
            "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
            "title": {"text": "Valeur"}
        }],
        "seriesParams": [{
            "show": true,
            "type": "line",
            "mode": "normal",
            "data": {"label": "CPU", "id": "1"},
            "valueAxis": "ValueAxis-1",
            "drawLinesBetweenPoints": true,
            "lineWidth": 2,
            "interpolate": "linear",
            "showCircles": true
        }],
        "addTooltip": true,
        "addLegend": true,
        "legendPosition": "right",
        "times": [],
        "addTimeMarker": false
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "avg",
            "schema": "metric",
            "params": {"field": "system.cpu.user.pct"}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "date_histogram",
            "schema": "segment",
            "params": {
                "field": "@timestamp",
                "timeRange": {"from": "now-15m", "to": "now"},
                "useNormalizedEsInterval": true,
                "scaleMetricValues": false,
                "interval": "auto",
                "drop_partials": false,
                "min_doc_count": 1,
                "extended_bounds": {}
            }
        }
    ]
}'

create_visualization "system-logs" "table" "filebeat-*" '{
    "title": "Logs système",
    "type": "table",
    "params": {
        "perPage": 10,
        "showPartialRows": false,
        "showMetricsAtAllLevels": false,
        "sort": {"columnIndex": null, "direction": null},
        "showTotal": false,
        "totalFunc": "sum"
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "terms",
            "schema": "bucket",
            "params": {
                "field": "message",
                "size": 5,
                "order": "desc",
                "orderBy": "1"
            }
        }
    ]
}'

# Visualisations pour les métriques d'application
create_visualization "application-metrics" "line" "application-*" '{
    "title": "Métriques d'application",
    "type": "line",
    "params": {
        "type": "line",
        "grid": {"categoryLines": false},
        "categoryAxes": [{
            "id": "CategoryAxis-1",
            "type": "category",
            "position": "bottom",
            "show": true,
            "style": {},
            "scale": {"type": "linear"},
            "labels": {"show": true, "filter": true, "truncate": 100},
            "title": {}
        }],
        "valueAxes": [{
            "id": "ValueAxis-1",
            "name": "LeftAxis-1",
            "type": "value",
            "position": "left",
            "show": true,
            "style": {},
            "scale": {"type": "linear", "mode": "normal"},
            "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
            "title": {"text": "Requêtes"}
        }],
        "seriesParams": [{
            "show": true,
            "type": "line",
            "mode": "normal",
            "data": {"label": "Requêtes", "id": "1"},
            "valueAxis": "ValueAxis-1",
            "drawLinesBetweenPoints": true,
            "lineWidth": 2,
            "interpolate": "linear",
            "showCircles": true
        }],
        "addTooltip": true,
        "addLegend": true,
        "legendPosition": "right",
        "times": [],
        "addTimeMarker": false
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "date_histogram",
            "schema": "segment",
            "params": {
                "field": "@timestamp",
                "timeRange": {"from": "now-15m", "to": "now"},
                "useNormalizedEsInterval": true,
                "scaleMetricValues": false,
                "interval": "auto",
                "drop_partials": false,
                "min_doc_count": 1,
                "extended_bounds": {}
            }
        }
    ]
}'

create_visualization "application-logs" "table" "application-*" '{
    "title": "Logs d'application",
    "type": "table",
    "params": {
        "perPage": 10,
        "showPartialRows": false,
        "showMetricsAtAllLevels": false,
        "sort": {"columnIndex": null, "direction": null},
        "showTotal": false,
        "totalFunc": "sum"
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "terms",
            "schema": "bucket",
            "params": {
                "field": "message",
                "size": 5,
                "order": "desc",
                "orderBy": "1"
            }
        }
    ]
}'

# Visualisations pour les événements de sécurité
create_visualization "security-events" "line" "security-*" '{
    "title": "Événements de sécurité",
    "type": "line",
    "params": {
        "type": "line",
        "grid": {"categoryLines": false},
        "categoryAxes": [{
            "id": "CategoryAxis-1",
            "type": "category",
            "position": "bottom",
            "show": true,
            "style": {},
            "scale": {"type": "linear"},
            "labels": {"show": true, "filter": true, "truncate": 100},
            "title": {}
        }],
        "valueAxes": [{
            "id": "ValueAxis-1",
            "name": "LeftAxis-1",
            "type": "value",
            "position": "left",
            "show": true,
            "style": {},
            "scale": {"type": "linear", "mode": "normal"},
            "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
            "title": {"text": "Événements"}
        }],
        "seriesParams": [{
            "show": true,
            "type": "line",
            "mode": "normal",
            "data": {"label": "Événements", "id": "1"},
            "valueAxis": "ValueAxis-1",
            "drawLinesBetweenPoints": true,
            "lineWidth": 2,
            "interpolate": "linear",
            "showCircles": true
        }],
        "addTooltip": true,
        "addLegend": true,
        "legendPosition": "right",
        "times": [],
        "addTimeMarker": false
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "date_histogram",
            "schema": "segment",
            "params": {
                "field": "@timestamp",
                "timeRange": {"from": "now-15m", "to": "now"},
                "useNormalizedEsInterval": true,
                "scaleMetricValues": false,
                "interval": "auto",
                "drop_partials": false,
                "min_doc_count": 1,
                "extended_bounds": {}
            }
        }
    ]
}'

create_visualization "security-alerts" "table" "security-*" '{
    "title": "Alertes de sécurité",
    "type": "table",
    "params": {
        "perPage": 10,
        "showPartialRows": false,
        "showMetricsAtAllLevels": false,
        "sort": {"columnIndex": null, "direction": null},
        "showTotal": false,
        "totalFunc": "sum"
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "terms",
            "schema": "bucket",
            "params": {
                "field": "message",
                "size": 5,
                "order": "desc",
                "orderBy": "1"
            }
        }
    ]
}'

# Visualisations pour les métriques de performance
create_visualization "performance-metrics" "line" "metrics-*" '{
    "title": "Métriques de performance",
    "type": "line",
    "params": {
        "type": "line",
        "grid": {"categoryLines": false},
        "categoryAxes": [{
            "id": "CategoryAxis-1",
            "type": "category",
            "position": "bottom",
            "show": true,
            "style": {},
            "scale": {"type": "linear"},
            "labels": {"show": true, "filter": true, "truncate": 100},
            "title": {}
        }],
        "valueAxes": [{
            "id": "ValueAxis-1",
            "name": "LeftAxis-1",
            "type": "value",
            "position": "left",
            "show": true,
            "style": {},
            "scale": {"type": "linear", "mode": "normal"},
            "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
            "title": {"text": "Temps de réponse"}
        }],
        "seriesParams": [{
            "show": true,
            "type": "line",
            "mode": "normal",
            "data": {"label": "Temps de réponse", "id": "1"},
            "valueAxis": "ValueAxis-1",
            "drawLinesBetweenPoints": true,
            "lineWidth": 2,
            "interpolate": "linear",
            "showCircles": true
        }],
        "addTooltip": true,
        "addLegend": true,
        "legendPosition": "right",
        "times": [],
        "addTimeMarker": false
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "avg",
            "schema": "metric",
            "params": {"field": "response_time"}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "date_histogram",
            "schema": "segment",
            "params": {
                "field": "@timestamp",
                "timeRange": {"from": "now-15m", "to": "now"},
                "useNormalizedEsInterval": true,
                "scaleMetricValues": false,
                "interval": "auto",
                "drop_partials": false,
                "min_doc_count": 1,
                "extended_bounds": {}
            }
        }
    ]
}'

create_visualization "performance-logs" "table" "metrics-*" '{
    "title": "Logs de performance",
    "type": "table",
    "params": {
        "perPage": 10,
        "showPartialRows": false,
        "showMetricsAtAllLevels": false,
        "sort": {"columnIndex": null, "direction": null},
        "showTotal": false,
        "totalFunc": "sum"
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "terms",
            "schema": "bucket",
            "params": {
                "field": "message",
                "size": 5,
                "order": "desc",
                "orderBy": "1"
            }
        }
    ]
}'

# Visualisations pour les métriques d'erreur
create_visualization "error-metrics" "line" "error-*" '{
    "title": "Métriques d'erreur",
    "type": "line",
    "params": {
        "type": "line",
        "grid": {"categoryLines": false},
        "categoryAxes": [{
            "id": "CategoryAxis-1",
            "type": "category",
            "position": "bottom",
            "show": true,
            "style": {},
            "scale": {"type": "linear"},
            "labels": {"show": true, "filter": true, "truncate": 100},
            "title": {}
        }],
        "valueAxes": [{
            "id": "ValueAxis-1",
            "name": "LeftAxis-1",
            "type": "value",
            "position": "left",
            "show": true,
            "style": {},
            "scale": {"type": "linear", "mode": "normal"},
            "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
            "title": {"text": "Erreurs"}
        }],
        "seriesParams": [{
            "show": true,
            "type": "line",
            "mode": "normal",
            "data": {"label": "Erreurs", "id": "1"},
            "valueAxis": "ValueAxis-1",
            "drawLinesBetweenPoints": true,
            "lineWidth": 2,
            "interpolate": "linear",
            "showCircles": true
        }],
        "addTooltip": true,
        "addLegend": true,
        "legendPosition": "right",
        "times": [],
        "addTimeMarker": false
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "date_histogram",
            "schema": "segment",
            "params": {
                "field": "@timestamp",
                "timeRange": {"from": "now-15m", "to": "now"},
                "useNormalizedEsInterval": true,
                "scaleMetricValues": false,
                "interval": "auto",
                "drop_partials": false,
                "min_doc_count": 1,
                "extended_bounds": {}
            }
        }
    ]
}'

create_visualization "error-logs" "table" "error-*" '{
    "title": "Logs d'erreur",
    "type": "table",
    "params": {
        "perPage": 10,
        "showPartialRows": false,
        "showMetricsAtAllLevels": false,
        "sort": {"columnIndex": null, "direction": null},
        "showTotal": false,
        "totalFunc": "sum"
    },
    "aggs": [
        {
            "id": "1",
            "enabled": true,
            "type": "count",
            "schema": "metric",
            "params": {}
        },
        {
            "id": "2",
            "enabled": true,
            "type": "terms",
            "schema": "bucket",
            "params": {
                "field": "message",
                "size": 5,
                "order": "desc",
                "orderBy": "1"
            }
        }
    ]
}'

# 3. Vérification
echo "3. Vérification des visualisations..."
if curl -s -u "$KIBANA_USER:$KIBANA_PASSWORD" "$KIBANA_URL/api/saved_objects/_find?type=visualization" | grep -q "\"total\":10"; then
    echo "✓ Toutes les visualisations sont configurées"
else
    echo "✗ Erreur: Certaines visualisations sont manquantes"
    exit 1
fi

echo "=== Configuration des visualisations terminée ===" 
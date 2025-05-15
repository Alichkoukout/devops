#!/bin/bash

echo "Vérification de la configuration du système de logging..."

# 1. Vérifier les services Docker
echo "1. Vérification des services Docker..."
docker-compose ps

# 2. Vérifier les certificats
echo "2. Vérification des certificats..."
for cert in elasticsearch kibana logstash filebeat; do
    if [ -f "/opt/monitoring/certs/$cert.crt" ] && [ -f "/opt/monitoring/certs/$cert.key" ]; then
        echo "✓ Certificats pour $cert trouvés"
    else
        echo "✗ Certificats pour $cert manquants"
    fi
done

# 3. Vérifier Elasticsearch
echo "3. Vérification d'Elasticsearch..."
if curl -s http://localhost:9200 > /dev/null; then
    echo "✓ Elasticsearch est accessible"
    # Vérifier les index
    echo "Index Elasticsearch :"
    curl -s http://localhost:9200/_cat/indices?v
else
    echo "✗ Elasticsearch n'est pas accessible"
fi

# 4. Vérifier Kibana
echo "4. Vérification de Kibana..."
if curl -s http://localhost:5601 > /dev/null; then
    echo "✓ Kibana est accessible"
    # Vérifier les index patterns
    echo "Index patterns Kibana :"
    curl -s -H "kbn-xsrf: true" http://localhost:5601/api/saved_objects/_find?type=index-pattern
else
    echo "✗ Kibana n'est pas accessible"
fi

# 5. Vérifier Logstash
echo "5. Vérification de Logstash..."
if curl -s http://localhost:9600 > /dev/null; then
    echo "✓ Logstash est accessible"
    # Vérifier les pipelines
    echo "Pipelines Logstash :"
    curl -s http://localhost:9600/_node/pipelines
else
    echo "✗ Logstash n'est pas accessible"
fi

# 6. Vérifier Filebeat
echo "6. Vérification de Filebeat..."
if docker exec filebeat filebeat test config; then
    echo "✓ Configuration Filebeat valide"
else
    echo "✗ Configuration Filebeat invalide"
fi

# 7. Vérifier les logs
echo "7. Vérification des logs..."
for service in elasticsearch kibana logstash filebeat; do
    if [ -f "/opt/monitoring/logs/$service.log" ]; then
        echo "✓ Logs pour $service trouvés"
        echo "Dernières lignes de log pour $service :"
        tail -n 5 "/opt/monitoring/logs/$service.log"
    else
        echo "✗ Logs pour $service manquants"
    fi
done

# 8. Vérifier les sauvegardes
echo "8. Vérification des sauvegardes..."
if [ -d "/opt/monitoring/backup" ]; then
    echo "✓ Répertoire de sauvegarde trouvé"
    echo "Sauvegardes récentes :"
    ls -l /opt/monitoring/backup/configs/
    ls -l /opt/monitoring/backup/indices/
else
    echo "✗ Répertoire de sauvegarde manquant"
fi

# 9. Vérifier les tâches cron
echo "9. Vérification des tâches cron..."
crontab -l | grep -E "backup-configs|backup-indices"

# 10. Vérifier les permissions
echo "10. Vérification des permissions..."
for dir in config logs data certs backup; do
    if [ -d "/opt/monitoring/$dir" ]; then
        echo "Permissions pour /opt/monitoring/$dir :"
        ls -ld "/opt/monitoring/$dir"
    fi
done

echo "Vérification terminée!" 
#!/bin/bash

# Vérifier si le mode production est activé
if [ "$1" = "production" ]; then
    ENV_FILE=".env.production"
else
    ENV_FILE=".env"
fi

echo "Initialisation du système de logging..."

# 1. Génération des certificats
echo "1. Génération des certificats..."
./monitoring/scripts/generate-certificates.sh $1

# 2. Création des répertoires nécessaires
echo "2. Création des répertoires..."
mkdir -p /opt/monitoring/{config,logs,data,certs,backup/{configs,indices}}

# 3. Copie des configurations
echo "3. Copie des configurations..."
cp -r monitoring/config/* /opt/monitoring/config/
cp -r monitoring/certs/* /opt/monitoring/certs/
cp $ENV_FILE /opt/monitoring/.env

# 4. Démarrage des services
echo "4. Démarrage des services..."

# Attendre qu'Elasticsearch soit prêt
echo "Démarrage d'Elasticsearch..."
docker-compose up -d elasticsearch
until curl -s http://localhost:9200 > /dev/null; do
    echo "En attente d'Elasticsearch..."
    sleep 5
done

# Créer les utilisateurs et rôles
echo "5. Création des utilisateurs et rôles..."
./monitoring/scripts/create-users.sh $1

# Démarrage des autres services
echo "6. Démarrage des autres services..."
docker-compose up -d logstash kibana filebeat

# 7. Configuration des index patterns
echo "7. Configuration des index patterns..."
until curl -s http://localhost:5601 > /dev/null; do
    echo "En attente de Kibana..."
    sleep 5
done

# Créer les index patterns
curl -X POST "http://localhost:5601/api/saved_objects/index-pattern/filebeat-*" \
     -H "kbn-xsrf: true" \
     -H "Content-Type: application/json" \
     -d '{"attributes":{"title":"filebeat-*","timeFieldName":"@timestamp"}}'

curl -X POST "http://localhost:5601/api/saved_objects/index-pattern/logstash-*" \
     -H "kbn-xsrf: true" \
     -H "Content-Type: application/json" \
     -d '{"attributes":{"title":"logstash-*","timeFieldName":"@timestamp"}}'

# 8. Import des dashboards
echo "8. Import des dashboards..."
curl -X POST "http://localhost:5601/api/saved_objects/_import" \
     -H "kbn-xsrf: true" \
     -F file=@monitoring/kibana/dashboards/application-logs.json

# 9. Configuration des alertes
echo "9. Configuration des alertes..."
if [ "$1" = "production" ]; then
    # Configurer les webhooks Slack
    curl -X PUT "http://localhost:9200/_watcher/watch/slack_alerts" \
         -H "Content-Type: application/json" \
         -u elastic:$ELASTIC_PASSWORD \
         -d '{
           "trigger": {
             "schedule": {
               "interval": "1m"
             }
           },
           "input": {
             "search": {
               "request": {
                 "indices": ["filebeat-*", "logstash-*"],
                 "body": {
                   "query": {
                     "bool": {
                       "must": [
                         {"match": {"level": "ERROR"}},
                         {"range": {"@timestamp": {"gte": "now-1m"}}}
                       ]
                     }
                   }
                 }
               }
             }
           },
           "condition": {
             "compare": {
               "ctx.payload.hits.total": {
                 "gt": 0
               }
             }
           },
           "actions": {
             "slack_alert": {
               "webhook": {
                 "url": "'$SLACK_WEBHOOK_URL'",
                 "method": "POST",
                 "body": "{\"text\":\"{{ctx.payload.hits.total}} erreurs détectées dans les dernières minutes\"}"
               }
             }
           }
         }'
fi

# 10. Configuration de la rotation des logs
echo "10. Configuration de la rotation des logs..."
cat > /etc/logrotate.d/monitoring << EOF
/opt/monitoring/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
EOF

# 11. Configuration des sauvegardes automatiques
echo "11. Configuration des sauvegardes automatiques..."
# Ajouter les tâches cron pour les sauvegardes
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/monitoring/scripts/backup-configs.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/monitoring/scripts/backup-indices.sh") | crontab -

# 12. Vérification finale
echo "12. Vérification finale..."
echo "Vérification des services..."
docker-compose ps

echo "Vérification des logs..."
tail -n 20 /opt/monitoring/logs/elasticsearch.log
tail -n 20 /opt/monitoring/logs/logstash.log
tail -n 20 /opt/monitoring/logs/kibana.log

echo "Initialisation terminée avec succès!" 
# Guide de Déploiement

## Préparation

### 1. Vérification des Prérequis
- Serveur avec accès SSH
- Docker et Docker Compose installés
- Base de données MySQL configurée
- Certificats SSL valides
- Domaine configuré

### 2. Configuration de l'Environnement de Production

#### Variables d'Environnement
Créez un fichier `.env.production` :
```env
# Base de données
DB_HOST=production-db-host
DB_PORT=3306
DB_NAME=authapp
DB_USERNAME=prod_user
DB_PASSWORD=secure_password

# JWT
JWT_SECRET=production_jwt_secret
JWT_EXPIRATION=86400000

# Frontend
REACT_APP_API_URL=https://api.votre-domaine.com

# Monitoring
PROMETHEUS_PASSWORD=secure_password
GRAFANA_PASSWORD=secure_password
ELASTIC_PASSWORD=secure_password
```

## Déploiement

### 1. Préparation du Code

#### Build des Images
```bash
# Build des images Docker
docker-compose -f docker-compose.prod.yml build

# Tag des images pour le registry
docker tag authapp-backend:latest votre-registry.com/authapp-backend:latest
docker tag authapp-frontend:latest votre-registry.com/authapp-frontend:latest
```

#### Push des Images
```bash
# Login au registry
docker login votre-registry.com

# Push des images
docker push votre-registry.com/authapp-backend:latest
docker push votre-registry.com/authapp-frontend:latest
```

### 2. Déploiement sur le Serveur

#### Configuration du Serveur
```bash
# Création des dossiers nécessaires
mkdir -p /opt/authapp/{config,data,logs}

# Copie des fichiers de configuration
scp .env.production user@server:/opt/authapp/config/.env
scp docker-compose.prod.yml user@server:/opt/authapp/
```

#### Démarrage des Services
```bash
cd /opt/authapp
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Configuration du Reverse Proxy

#### Nginx Configuration
```nginx
server {
    listen 443 ssl;
    server_name api.votre-domaine.com;

    ssl_certificate /etc/letsencrypt/live/votre-domaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votre-domaine.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name app.votre-domaine.com;

    ssl_certificate /etc/letsencrypt/live/votre-domaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votre-domaine.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Vérification

### 1. Vérification des Services
```bash
# Vérification des conteneurs
docker-compose -f docker-compose.prod.yml ps

# Vérification des logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 2. Tests de Santé
```bash
# Test de l'API
curl https://api.votre-domaine.com/health

# Test du frontend
curl https://app.votre-domaine.com
```

### 3. Vérification du Monitoring
- Accédez à Grafana : https://monitoring.votre-domaine.com
- Vérifiez les métriques
- Vérifiez les alertes

## Maintenance

### 1. Mise à Jour
```bash
# Pull des nouvelles images
docker-compose -f docker-compose.prod.yml pull

# Redémarrage des services
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Sauvegarde
```bash
# Sauvegarde de la base de données
mysqldump -u prod_user -p authapp > backup.sql

# Sauvegarde des volumes Docker
docker run --rm -v authapp_data:/data -v $(pwd):/backup alpine tar czf /backup/data.tar.gz /data
```

### 3. Restauration
```bash
# Restauration de la base de données
mysql -u prod_user -p authapp < backup.sql

# Restauration des volumes
docker run --rm -v authapp_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/data.tar.gz"
```

## Sécurité

### 1. Configuration du Pare-feu
```bash
# Ouverture des ports nécessaires
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
```

### 2. Mise à Jour de la Sécurité
```bash
# Mise à jour du système
apt update && apt upgrade

# Mise à jour des conteneurs
docker-compose -f docker-compose.prod.yml pull
```

### 3. Monitoring de la Sécurité
- Vérification des logs de sécurité
- Analyse des tentatives d'intrusion
- Mise à jour des certificats SSL

## Dépannage

### 1. Problèmes Courants

#### Service Inaccessible
```bash
# Vérification des logs
docker-compose -f docker-compose.prod.yml logs -f service_name

# Redémarrage du service
docker-compose -f docker-compose.prod.yml restart service_name
```

#### Problèmes de Base de Données
```bash
# Vérification de la connexion
mysql -u prod_user -p -h localhost authapp

# Vérification des logs MySQL
docker-compose -f docker-compose.prod.yml logs -f mysql
```

#### Problèmes de Performance
```bash
# Vérification des ressources
docker stats

# Vérification des logs d'application
docker-compose -f docker-compose.prod.yml logs -f backend
```

### 2. Procédure de Rollback
```bash
# Rollback vers une version précédente
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --no-recreate
```

## Support

### 1. Contact
- Support technique : support@votre-domaine.com
- Urgences : +XX XX XX XX XX

### 2. Documentation
- Documentation technique : https://docs.votre-domaine.com
- Guide d'utilisation : https://help.votre-domaine.com

### 3. Monitoring
- Grafana : https://monitoring.votre-domaine.com
- Kibana : https://logs.votre-domaine.com

## Déploiement du Système de Logging

### 1. Préparation

#### Configuration de l'Environnement de Production
Créez un fichier `.env.production` dans le dossier `monitoring` :
```env
# Elasticsearch
ELASTIC_PASSWORD=production_elastic_password
ELASTIC_USER=elastic

# Kibana
KIBANA_ENCRYPTION_KEY=production_encryption_key

# Logstash
SLACK_WEBHOOK_URL=production_slack_webhook

# Monitoring
PROMETHEUS_PASSWORD=production_prometheus_password
GRAFANA_PASSWORD=production_grafana_password
```

### 2. Déploiement des Services

#### Build des Images
```bash
# Build des images Docker
docker-compose -f docker-compose.prod.yml build

# Tag des images pour le registry
docker tag elasticsearch:latest votre-registry.com/elasticsearch:latest
docker tag logstash:latest votre-registry.com/logstash:latest
docker tag kibana:latest votre-registry.com/kibana:latest
docker tag filebeat:latest votre-registry.com/filebeat:latest
```

#### Push des Images
```bash
# Login au registry
docker login votre-registry.com

# Push des images
docker push votre-registry.com/elasticsearch:latest
docker push votre-registry.com/logstash:latest
docker push votre-registry.com/kibana:latest
docker push votre-registry.com/filebeat:latest
```

### 3. Configuration du Serveur

#### Préparation des Volumes
```bash
# Création des dossiers pour les volumes
mkdir -p /opt/monitoring/{elasticsearch,logstash,kibana,filebeat}

# Configuration des permissions
chown -R 1000:1000 /opt/monitoring/elasticsearch
chown -R 1000:1000 /opt/monitoring/logstash
chown -R 1000:1000 /opt/monitoring/kibana
chown -R 1000:1000 /opt/monitoring/filebeat
```

#### Configuration des Services
```bash
# Copie des fichiers de configuration
scp .env.production user@server:/opt/monitoring/.env
scp docker-compose.prod.yml user@server:/opt/monitoring/
scp -r monitoring/* user@server:/opt/monitoring/config/
```

### 4. Démarrage des Services

#### Démarrage Séquentiel
```bash
# Démarrer Elasticsearch
docker-compose -f docker-compose.prod.yml up -d elasticsearch

# Attendre que Elasticsearch soit prêt
while ! curl -s http://localhost:9200 > /dev/null; do
    sleep 5
done

# Démarrer Logstash
docker-compose -f docker-compose.prod.yml up -d logstash

# Démarrer Kibana
docker-compose -f docker-compose.prod.yml up -d kibana

# Démarrer Filebeat
docker-compose -f docker-compose.prod.yml up -d filebeat
```

### 5. Configuration du Reverse Proxy

#### Nginx Configuration
```nginx
# Configuration pour Kibana
server {
    listen 443 ssl;
    server_name logs.votre-domaine.com;

    ssl_certificate /etc/letsencrypt/live/votre-domaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votre-domaine.com/privkey.pem;

    location / {
        proxy_pass http://localhost:5601;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 6. Vérification

#### Vérification des Services
```bash
# Vérifier l'état des services
docker-compose -f docker-compose.prod.yml ps

# Vérifier les logs
docker-compose -f docker-compose.prod.yml logs -f
```

#### Tests de Santé
```bash
# Test d'Elasticsearch
curl -u elastic:production_elastic_password https://logs.votre-domaine.com/_cluster/health

# Test de Kibana
curl -u elastic:production_elastic_password https://logs.votre-domaine.com/api/status
```

### 7. Configuration des Alertes

#### Configuration des Webhooks
```bash
# Configurer le webhook Slack
curl -X PUT "https://logs.votre-domaine.com/_cluster/settings" \
     -H "Content-Type: application/json" \
     -u elastic:production_elastic_password \
     -d '{
       "persistent": {
         "xpack.notification.slack.webhook.url": "production_slack_webhook"
       }
     }'
```

#### Configuration des Règles d'Alerte
```bash
# Importer les règles d'alerte
curl -X POST "https://logs.votre-domaine.com/_watcher/watch" \
     -H "Content-Type: application/json" \
     -u elastic:production_elastic_password \
     -d @monitoring/alert-rules.json
```

### 8. Maintenance

#### Sauvegarde
```bash
# Sauvegarde des index
curl -X PUT "https://logs.votre-domaine.com/_snapshot/backup" \
     -H "Content-Type: application/json" \
     -u elastic:production_elastic_password \
     -d '{
       "type": "fs",
       "settings": {
         "location": "/opt/monitoring/backup"
       }
     }'

# Créer un snapshot
curl -X PUT "https://logs.votre-domaine.com/_snapshot/backup/snapshot_$(date +%Y%m%d)" \
     -u elastic:production_elastic_password
```

#### Nettoyage
```bash
# Nettoyer les anciens logs
curl -X DELETE "https://logs.votre-domaine.com/filebeat-*-$(date -d '30 days ago' +%Y.%m.%d)" \
     -u elastic:production_elastic_password
```

### 9. Monitoring

#### Configuration de Prometheus
```yaml
# Ajouter les targets dans prometheus.yml
scrape_configs:
  - job_name: 'elasticsearch'
    static_configs:
      - targets: ['elasticsearch:9200']
    metrics_path: '/_prometheus/metrics'
    scheme: 'http'

  - job_name: 'logstash'
    static_configs:
      - targets: ['logstash:9600']
    metrics_path: '/metrics'
    scheme: 'http'
```

#### Configuration de Grafana
```bash
# Importer le dashboard
curl -X POST "https://monitoring.votre-domaine.com/api/dashboards/db" \
     -H "Content-Type: application/json" \
     -u admin:production_grafana_password \
     -d @monitoring/grafana/dashboards/logging.json
```

### 10. Sécurité

#### Configuration des Certificats
```bash
# Générer les certificats
./scripts/generate-certificates.sh production

# Configurer les certificats dans les services
docker-compose -f docker-compose.prod.yml up -d
```

#### Configuration des Utilisateurs
```bash
# Créer les utilisateurs de production
./scripts/create-users.sh production

# Configurer les rôles et permissions
curl -X PUT "https://logs.votre-domaine.com/_security/role/logging_admin" \
     -H "Content-Type: application/json" \
     -u elastic:production_elastic_password \
     -d @monitoring/security/roles.json
``` 
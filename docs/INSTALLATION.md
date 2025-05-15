# Guide d'Installation

## Prérequis

### Système
- Java 17 ou supérieur
- Node.js 18 ou supérieur
- Docker et Docker Compose
- MySQL 8.0 ou supérieur
- Git

### Outils de Développement
- IDE (IntelliJ IDEA, VS Code, etc.)
- Postman ou équivalent pour tester les API
- Terminal avec accès SSH

## Installation

### 1. Cloner le Repository
```bash
git clone https://github.com/votre-org/authapp.git
cd authapp
```

### 2. Configuration de l'Environnement

#### Variables d'Environnement
Créez un fichier `.env` à la racine du projet :
```env
# Base de données
DB_HOST=localhost
DB_PORT=3306
DB_NAME=authapp
DB_USERNAME=root
DB_PASSWORD=votre_mot_de_passe

# JWT
JWT_SECRET=votre_secret_jwt
JWT_EXPIRATION=86400000

# Frontend
REACT_APP_API_URL=http://localhost:8080/api
```

### 3. Installation du Backend

#### Configuration Maven
```bash
cd backendpfa
mvn clean install
```

#### Configuration de la Base de Données
1. Créez une base de données MySQL :
```sql
CREATE DATABASE authapp;
```

2. Configurez les propriétés dans `application.yml` :
```yaml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
```

### 4. Installation du Frontend

#### Installation des Dépendances
```bash
cd frontendpfa
npm install
```

#### Configuration de l'Environnement
Créez un fichier `.env` dans le dossier frontend :
```env
REACT_APP_API_URL=http://localhost:8080/api
```

### 5. Installation avec Docker

#### Build des Images
```bash
docker-compose build
```

#### Démarrage des Services
```bash
docker-compose up -d
```

## Vérification de l'Installation

### 1. Vérifier le Backend
```bash
curl http://localhost:8080/api/health
```
Résultat attendu : `{"status":"UP"}`

### 2. Vérifier le Frontend
Ouvrez `http://localhost:3000` dans votre navigateur

### 3. Vérifier la Base de Données
```bash
mysql -u root -p authapp
```
```sql
SHOW TABLES;
```

## Configuration du Monitoring

### 1. Prometheus
```bash
cd monitoring
docker-compose up -d prometheus
```
Accédez à `http://localhost:9090`

### 2. Grafana
```bash
docker-compose up -d grafana
```
Accédez à `http://localhost:3000`
- Identifiants par défaut : admin/admin
- Configurez la source de données Prometheus

### 3. ELK Stack
```bash
docker-compose up -d elasticsearch kibana logstash
```
Accédez à `http://localhost:5601`

## Installation du Système de Logging

### 1. Prérequis
- Docker et Docker Compose
- Au moins 4GB de RAM disponible
- 20GB d'espace disque libre

### 2. Configuration de l'Environnement
Créez un fichier `.env` dans le dossier `monitoring` :
```env
# Elasticsearch
ELASTIC_PASSWORD=votre_mot_de_passe_elastic
ELASTIC_USER=elastic

# Kibana
KIBANA_ENCRYPTION_KEY=votre_cle_encryption

# Logstash
SLACK_WEBHOOK_URL=votre_webhook_slack
```

### 3. Installation des Services

#### Elasticsearch
```bash
# Créer le réseau Docker
docker network create monitoring

# Démarrer Elasticsearch
docker-compose -f docker-compose.yml up -d elasticsearch

# Vérifier l'état
curl -u elastic:votre_mot_de_passe_elastic http://localhost:9200
```

#### Logstash
```bash
# Démarrer Logstash
docker-compose -f docker-compose.yml up -d logstash

# Vérifier les logs
docker-compose logs -f logstash
```

#### Kibana
```bash
# Démarrer Kibana
docker-compose -f docker-compose.yml up -d kibana

# Accéder à l'interface
http://localhost:5601
```

#### Filebeat
```bash
# Démarrer Filebeat
docker-compose -f docker-compose.yml up -d filebeat

# Vérifier les logs
docker-compose logs -f filebeat
```

### 4. Configuration des Index Patterns

1. Ouvrir Kibana (http://localhost:5601)
2. Aller dans "Stack Management" > "Index Patterns"
3. Créer les index patterns suivants :
   - `filebeat-*`
   - `logstash-*`

### 5. Import des Tableaux de Bord

1. Dans Kibana, aller dans "Stack Management" > "Saved Objects"
2. Cliquer sur "Import"
3. Sélectionner le fichier `monitoring/kibana/dashboards/application-logs.json`

### 6. Vérification

#### Vérifier la Collecte des Logs
```bash
# Générer des logs de test
curl -X POST http://localhost:8080/api/test/log

# Vérifier dans Kibana
# Aller dans "Discover" et chercher les logs récents
```

#### Vérifier les Alertes
```bash
# Générer une erreur
curl -X POST http://localhost:8080/api/test/error

# Vérifier les alertes dans Slack
```

### 7. Configuration de la Rotation des Logs

#### Filebeat
```yaml
# Dans filebeat.yml
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
```

#### Logstash
```conf
# Dans logstash.conf
output {
  elasticsearch {
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
```

### 8. Sécurité

#### Configuration des Certificats
```bash
# Générer les certificats
./scripts/generate-certificates.sh

# Configurer les certificats dans les services
```

#### Configuration des Utilisateurs
```bash
# Créer les utilisateurs dans Elasticsearch
./scripts/create-users.sh

# Configurer les rôles et permissions
```

### 9. Maintenance

#### Nettoyage des Logs
```bash
# Nettoyer les anciens logs
curl -X DELETE "http://localhost:9200/filebeat-*-$(date -d '30 days ago' +%Y.%m.%d)"
```

#### Sauvegarde
```bash
# Sauvegarder les configurations
./scripts/backup-configs.sh

# Sauvegarder les index
./scripts/backup-indices.sh
```

### 10. Dépannage

#### Vérification des Services
```bash
# Vérifier l'état des services
docker-compose ps

# Vérifier les logs
docker-compose logs -f
```

#### Problèmes Courants
1. Elasticsearch ne démarre pas
   - Vérifier la mémoire disponible
   - Vérifier les permissions des volumes

2. Logstash ne reçoit pas les logs
   - Vérifier la configuration de Filebeat
   - Vérifier la connectivité réseau

3. Kibana ne peut pas se connecter à Elasticsearch
   - Vérifier les credentials
   - Vérifier la configuration des hosts

## Mise à Jour

### 1. Mise à Jour du Code
```bash
git pull origin main
```

### 2. Mise à Jour des Dépendances
```bash
# Backend
cd backendpfa
mvn clean install

# Frontend
cd frontendpfa
npm update
```

### 3. Mise à Jour des Conteneurs
```bash
docker-compose pull
docker-compose up -d
```

## Support

Pour toute question ou problème :
1. Consultez la documentation
2. Vérifiez les issues GitHub
3. Contactez l'équipe de support

## Sécurité

### Bonnes Pratiques
1. Changez les mots de passe par défaut
2. Utilisez des secrets sécurisés
3. Activez le pare-feu
4. Mettez à jour régulièrement les dépendances

### Audit de Sécurité
1. Exécutez les tests de sécurité
2. Vérifiez les vulnérabilités connues
3. Mettez en place un monitoring de sécurité 
# Documentation Technique

## Architecture du Système

### Vue d'ensemble
Le système est construit selon une architecture microservices avec les composants suivants :
- Backend Spring Boot
- Frontend React
- Base de données MySQL
- Système de monitoring (Prometheus + Grafana)
- Système de logging (ELK Stack)

### Composants Principaux

#### Backend (Spring Boot)
- **Authentification** : Gestion des utilisateurs et de l'authentification JWT
- **API REST** : Endpoints pour les opérations CRUD
- **Sécurité** : Configuration Spring Security
- **Base de données** : JPA/Hibernate pour la persistance

#### Frontend (React)
- **Interface utilisateur** : Composants React modernes
- **Gestion d'état** : Redux pour la gestion de l'état global
- **Routing** : React Router pour la navigation
- **Tests** : Jest et React Testing Library

#### Infrastructure
- **Conteneurisation** : Docker pour l'isolation des services
- **Orchestration** : Docker Compose pour le développement local
- **CI/CD** : GitHub Actions pour l'intégration continue
- **Monitoring** : Prometheus pour la collecte de métriques
- **Logging** : ELK Stack pour la gestion des logs

## Configuration Technique

### Backend

#### Configuration Spring Boot
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/authapp
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
  security:
    jwt:
      secret: ${JWT_SECRET}
      expiration: 86400000
```

#### Sécurité
- Authentification JWT
- Protection CSRF
- Validation des entrées
- Rate limiting
- Protection contre les attaques XSS et SQL Injection

#### Tests
- Tests unitaires avec JUnit 5
- Tests d'intégration avec Spring Test
- Tests de performance avec JMeter
- Tests de sécurité avec OWASP ZAP

### Frontend

#### Configuration React
```javascript
// package.json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "redux": "^4.2.1",
    "axios": "^1.3.2"
  }
}
```

#### Tests Frontend
- Tests unitaires avec Jest
- Tests d'intégration avec React Testing Library
- Tests E2E avec Cypress

## Monitoring et Logging

### Prometheus
- Métriques système
- Métriques applicatives
- Alertes configurées

### Grafana
- Tableaux de bord personnalisés
- Visualisation des métriques
- Alertes en temps réel

### ELK Stack
- Collecte des logs
- Analyse des logs
- Visualisation des logs

## Système de Logging (ELK Stack)

### Configuration

#### 1. Filebeat
- Collecte les logs de l'application Spring Boot
- Collecte les logs Nginx
- Collecte les logs MySQL
- Envoie les logs à Logstash

Configuration dans `monitoring/filebeat/filebeat.yml` :
```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/application/*.log
  fields:
    type: spring-boot
  fields_under_root: true
  json.keys_under_root: true
  json.add_error_key: true
```

#### 2. Logstash
- Reçoit les logs de Filebeat
- Filtre et transforme les logs selon leur type
- Envoie les logs à Elasticsearch
- Envoie des alertes Slack pour les erreurs critiques

Configuration dans `monitoring/logstash/pipeline/logstash.conf` :
```conf
input {
  beats {
    port => 5044
  }
  tcp {
    port => 5000
    codec => json
  }
}

filter {
  if [type] == "spring-boot" {
    grok {
      match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}" }
    }
  }
}
```

#### 3. Kibana
- Interface de visualisation des logs
- Tableaux de bord personnalisés
- Alertes et notifications

Configuration dans `monitoring/kibana/kibana.yml` :
```yaml
server.name: kibana
server.host: "0.0.0.0"
elasticsearch.hosts: [ "http://elasticsearch:9200" ]
```

### Tableaux de Bord

#### 1. Application Logs Dashboard
- Visualisation des erreurs
- Timeline des logs
- Distribution des logs par type

Configuration dans `monitoring/kibana/dashboards/application-logs.json`

### Utilisation

#### 1. Démarrage des Services
```bash
# Démarrer tous les services
docker-compose -f docker-compose.yml up -d

# Vérifier l'état des services
docker-compose ps
```

#### 2. Accès aux Interfaces
- Kibana : http://localhost:5601
- Logstash : http://localhost:5044
- Elasticsearch : http://localhost:9200

#### 3. Visualisation des Logs
1. Ouvrir Kibana
2. Aller dans la section "Discover"
3. Sélectionner l'index pattern approprié
4. Utiliser les filtres pour affiner la recherche

#### 4. Configuration des Alertes
1. Dans Kibana, aller dans "Stack Monitoring"
2. Configurer les règles d'alerte
3. Définir les conditions de déclenchement
4. Configurer les notifications (email, Slack, etc.)

### Maintenance

#### 1. Rotation des Logs
- Configuration de la rotation dans Filebeat
- Nettoyage périodique des anciens logs
- Archivage des logs importants

#### 2. Surveillance
- Vérification régulière de l'espace disque
- Monitoring des performances
- Vérification des alertes

#### 3. Sauvegarde
- Sauvegarde régulière des configurations
- Export des tableaux de bord
- Sauvegarde des index Elasticsearch

### Dépannage

#### 1. Problèmes Courants
- Logs non reçus par Logstash
- Problèmes de performance
- Erreurs de configuration

#### 2. Solutions
- Vérifier les configurations
- Consulter les logs des services
- Redémarrer les services si nécessaire

### Bonnes Pratiques

#### 1. Configuration
- Utiliser des patterns de log cohérents
- Configurer des niveaux de log appropriés
- Mettre en place des alertes pertinentes

#### 2. Sécurité
- Sécuriser les accès aux interfaces
- Chiffrer les communications
- Gérer les permissions

#### 3. Performance
- Optimiser les requêtes Elasticsearch
- Configurer la rétention des logs
- Surveiller l'utilisation des ressources

## Déploiement

### Environnements
1. **Développement**
   - Base de données locale
   - Services en conteneurs Docker
   - Hot-reload activé

2. **Staging**
   - Environnement de test
   - Données de test
   - Tests automatisés

3. **Production**
   - Infrastructure cloud
   - Haute disponibilité
   - Monitoring actif

### Procédure de Déploiement
1. Build des images Docker
2. Tests automatisés
3. Déploiement sur l'environnement cible
4. Vérification de la santé
5. Activation du trafic

## Sécurité

### Mesures de Sécurité
- Chiffrement des données sensibles
- Validation des entrées
- Protection contre les attaques courantes
- Audit de sécurité régulier

### Bonnes Pratiques
- Mise à jour régulière des dépendances
- Rotation des secrets
- Journalisation des événements de sécurité
- Formation des développeurs

## Maintenance

### Procédures de Maintenance
1. Sauvegarde des données
2. Mise à jour des dépendances
3. Nettoyage des logs
4. Optimisation des performances

### Monitoring
- Surveillance des métriques clés
- Alertes automatiques
- Rapports de performance
- Analyse des tendances

## Support

### Documentation
- Guide d'installation
- Guide d'utilisation
- Guide de dépannage
- FAQ

### Contact
- Support technique
- Équipe de développement
- Urgences 
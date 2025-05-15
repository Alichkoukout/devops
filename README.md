# Système de Monitoring DevOps

Un système de monitoring complet basé sur la stack ELK (Elasticsearch, Logstash, Kibana) avec des fonctionnalités avancées de surveillance et d'alerte.

## Fonctionnalités

- **Monitoring des Logs**
  - Collecte centralisée des logs
  - Analyse en temps réel
  - Recherche avancée
  - Visualisations personnalisées

- **Monitoring des Métriques**
  - Métriques système (CPU, mémoire, disque)
  - Métriques applicatives
  - Alertes configurables
  - Tableaux de bord personnalisés

- **Sécurité**
  - Authentification
  - Autorisation basée sur les rôles
  - Chiffrement des communications
  - Audit des accès

## Prérequis

- Docker et Docker Compose
- 4GB RAM minimum
- 20GB espace disque
- Linux/Unix système

## Installation

1. Cloner le repository :
```bash
git clone https://github.com/Alichkoukout/devops.git
cd devops
```

2. Configurer les variables d'environnement :
```bash
cp .env.example .env
# Éditer .env avec vos configurations
```

3. Démarrer les services :
```bash
docker-compose up -d
```

4. Vérifier que les services sont opérationnels :
```bash
./monitoring/scripts/check-services.sh
```

## Configuration

### Elasticsearch
- URL: http://localhost:9200
- Configuration: `monitoring/config/elasticsearch/elasticsearch.yml`

### Kibana
- URL: http://localhost:5601
- Configuration: `monitoring/config/kibana/kibana.yml`

### Logstash
- Configuration: `monitoring/config/logstash/pipelines/`

### Filebeat
- Configuration: `monitoring/config/filebeat/filebeat.yml`

## Utilisation

### Accès à Kibana
1. Ouvrir http://localhost:5601
2. Se connecter avec les identifiants par défaut :
   - Utilisateur: elastic
   - Mot de passe: [votre mot de passe]

### Configuration des Dashboards
1. Aller dans Kibana > Dashboard
2. Importer les dashboards prédéfinis :
   - System Overview
   - Application Metrics
   - Security Monitoring

### Configuration des Alertes
1. Aller dans Kibana > Alerting
2. Créer de nouvelles règles d'alerte
3. Configurer les conditions et les actions

## Maintenance

### Sauvegarde
```bash
./monitoring/scripts/backup-configs.sh
```

### Restauration
```bash
./monitoring/scripts/restore-configs.sh /chemin/vers/backup.tar.gz
```

### Mise à jour
```bash
./monitoring/scripts/update-components.sh
```

## Développement

### Structure du Projet
```
.
├── docs/                    # Documentation
├── monitoring/             # Configuration du monitoring
│   ├── config/            # Fichiers de configuration
│   ├── scripts/           # Scripts utilitaires
│   └── dashboards/        # Dashboards Kibana
├── .github/               # Configuration GitHub
└── docker-compose.yml     # Configuration Docker
```

### Tests
```bash
# Tests unitaires
./monitoring/scripts/run-tests.sh

# Tests d'intégration
./monitoring/scripts/run-integration-tests.sh
```

## Contribution

Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour les directives de contribution.

## Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails. 
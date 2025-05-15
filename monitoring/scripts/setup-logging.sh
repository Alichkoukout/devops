#!/bin/bash

# Vérification des variables d'environnement requises
echo "Vérification des variables d'environnement..."
required_vars=(
    "ELASTIC_PASSWORD"
    "LOGSTASH_PASSWORD"
    "KIBANA_PASSWORD"
    "FILEBEAT_PASSWORD"
    "SLACK_WEBHOOK_URL"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Erreur: La variable $var n'est pas définie"
        exit 1
    fi
done

# Fonction pour vérifier le succès des commandes
check_status() {
    if [ $? -eq 0 ]; then
        echo "✓ $1"
    else
        echo "✗ Erreur lors de $1"
        exit 1
    fi
}

echo "=== Démarrage de la configuration du système de logging ==="

# 1. Génération des certificats
echo "1. Génération des certificats..."
./monitoring/scripts/generate-certificates.sh
check_status "Génération des certificats"

# 2. Création des utilisateurs
echo "2. Création des utilisateurs..."
./monitoring/scripts/create-users.sh
check_status "Création des utilisateurs"

# 3. Configuration des index patterns
echo "3. Configuration des index patterns..."
./monitoring/scripts/configure-index-patterns.sh
check_status "Configuration des index patterns"

# 4. Configuration des pipelines Logstash
echo "4. Configuration des pipelines Logstash..."
./monitoring/scripts/configure-logstash-pipelines.sh
check_status "Configuration des pipelines Logstash"

# 5. Configuration des patterns Grok
echo "5. Configuration des patterns Grok..."
./monitoring/scripts/configure-grok-patterns.sh
check_status "Configuration des patterns Grok"

# 6. Import des configurations Kibana
echo "6. Import des configurations Kibana..."
./monitoring/scripts/import-kibana-config.sh
check_status "Import des configurations Kibana"

# 7. Configuration des alertes
echo "7. Configuration des alertes..."
./monitoring/scripts/configure-alerts.sh
check_status "Configuration des alertes"

# 8. Configuration de la rotation des logs
echo "8. Configuration de la rotation des logs..."
./monitoring/scripts/rotate-logs.sh
check_status "Configuration de la rotation des logs"

# 9. Sauvegarde des configurations
echo "9. Sauvegarde des configurations..."
./monitoring/scripts/backup-configs.sh
check_status "Sauvegarde des configurations"

# 10. Vérification finale
echo "10. Vérification finale des services..."
./monitoring/scripts/check-services.sh
check_status "Vérification des services"

echo "=== Configuration du système de logging terminée avec succès ==="
echo "Les services sont maintenant prêts à être utilisés."
echo "Vous pouvez accéder à Kibana sur http://localhost:5601"
echo "Utilisez les identifiants suivants :"
echo "- Utilisateur: elastic"
echo "- Mot de passe: $ELASTIC_PASSWORD" 
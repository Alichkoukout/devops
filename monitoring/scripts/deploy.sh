#!/bin/bash

# Configuration
ENVIRONMENT=$1
REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME="monitoring-cluster"
SERVICE_NAME="monitoring-service"

# Vérifier l'environnement
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Environments: staging, production"
    exit 1
fi

# Fonction pour vérifier les prérequis
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed"
        exit 1
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed"
        exit 1
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose is not installed"
        exit 1
    fi
    
    echo "✅ All prerequisites are met"
}

# Fonction pour construire les images Docker
build_images() {
    echo "Building Docker images..."
    
    # Construire les images
    docker-compose build
    
    # Taguer les images
    docker tag monitoring-elasticsearch:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-elasticsearch:$ENVIRONMENT
    docker tag monitoring-kibana:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-kibana:$ENVIRONMENT
    docker tag monitoring-logstash:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-logstash:$ENVIRONMENT
    docker tag monitoring-filebeat:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-filebeat:$ENVIRONMENT
    docker tag monitoring-prometheus:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-prometheus:$ENVIRONMENT
    docker tag monitoring-grafana:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-grafana:$ENVIRONMENT
    
    echo "✅ Docker images built and tagged"
}

# Fonction pour pousser les images vers ECR
push_images() {
    echo "Pushing images to ECR..."
    
    # Se connecter à ECR
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    
    # Pousser les images
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-elasticsearch:$ENVIRONMENT
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-kibana:$ENVIRONMENT
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-logstash:$ENVIRONMENT
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-filebeat:$ENVIRONMENT
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-prometheus:$ENVIRONMENT
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/monitoring-grafana:$ENVIRONMENT
    
    echo "✅ Images pushed to ECR"
}

# Fonction pour mettre à jour le service ECS
update_service() {
    echo "Updating ECS service..."
    
    # Mettre à jour le service
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment
    
    echo "✅ ECS service updated"
}

# Fonction pour vérifier le déploiement
check_deployment() {
    echo "Checking deployment status..."
    
    # Attendre que le déploiement soit terminé
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME
    
    echo "✅ Deployment completed successfully"
}

# Fonction pour sauvegarder les configurations
backup_configs() {
    echo "Backing up configurations..."
    
    # Créer un backup
    ./monitoring/scripts/backup-configs.sh
    
    echo "✅ Configurations backed up"
}

# Exécuter le déploiement
echo "Starting deployment to $ENVIRONMENT..."

check_prerequisites
backup_configs
build_images
push_images
update_service
check_deployment

echo "✅ Deployment to $ENVIRONMENT completed successfully" 
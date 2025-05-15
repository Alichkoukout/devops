#!/bin/bash

# Configuration des variables
LOGSTASH_DIR="/etc/logstash"
PATTERNS_DIR="$LOGSTASH_DIR/patterns"
MAX_RETRIES=30
RETRY_INTERVAL=10

# Fonction pour créer un pattern
create_pattern() {
    local name=$1
    local pattern=$2

    echo "Création du pattern: $name..."
    
    # Vérifier si le pattern existe déjà
    if [ ! -f "$PATTERNS_DIR/$name" ]; then
        # Créer le pattern
        echo "$pattern" > "$PATTERNS_DIR/$name"
        
        if [ $? -eq 0 ]; then
            echo "✓ Pattern $name créé avec succès"
            return 0
        else
            echo "✗ Erreur lors de la création du pattern $name"
            return 1
        fi
    else
        echo "! Pattern $name existe déjà, mise à jour..."
        # Mettre à jour le pattern
        echo "$pattern" > "$PATTERNS_DIR/$name"
        
        if [ $? -eq 0 ]; then
            echo "✓ Pattern $name mis à jour avec succès"
            return 0
        else
            echo "✗ Erreur lors de la mise à jour du pattern $name"
            return 1
        fi
    fi
}

# 1. Créer le répertoire des patterns
echo "1. Création du répertoire des patterns..."
mkdir -p "$PATTERNS_DIR"

# 2. Créer les patterns
echo "2. Création des patterns..."

# Pattern pour les logs système
create_pattern "system" '
SYSLOGBASE %{SYSLOGTIMESTAMP:timestamp} %{SYSLOGFACILITY:facility} %{SYSLOGPRIORITY:priority} %{SYSLOGHOST:hostname} %{PROG:program}(?:\[%{POSINT:pid}\])?: %{GREEDYDATA:message}
SYSLOGTIMESTAMP %{MONTH} +%{MONTHDAY} %{TIME}
SYSLOGFACILITY %{WORD}
SYSLOGPRIORITY %{WORD}
SYSLOGHOST %{HOSTNAME}
PROG %{WORD}
'

# Pattern pour les logs d'application
create_pattern "application" '
APPLICATION %{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}
TIMESTAMP_ISO8601 %{YEAR}-%{MONTHNUM}-%{MONTHDAY}[T ]%{HOUR}:?%{MINUTE}(?::?%{SECOND})?%{ISO8601_TIMEZONE}?
LOGLEVEL (?:ERROR|WARN|INFO|DEBUG|TRACE)
'

# Pattern pour les logs de sécurité
create_pattern "security" '
SECURITY %{TIMESTAMP_ISO8601:timestamp} %{WORD:event_type} %{WORD:severity} %{IP:source_ip} %{GREEDYDATA:message}
'

# Pattern pour les métriques
create_pattern "metrics" '
METRICS %{TIMESTAMP_ISO8601:timestamp} %{WORD:metric_name} %{NUMBER:metric_value} %{GREEDYDATA:tags}
'

# Pattern pour les logs d'erreur
create_pattern "error" '
ERROR %{TIMESTAMP_ISO8601:timestamp} %{WORD:error_type} %{GREEDYDATA:message} %{GREEDYDATA:stack_trace}
'

# 3. Configurer les permissions
echo "3. Configuration des permissions..."
chown -R logstash:logstash "$PATTERNS_DIR"
chmod 750 "$PATTERNS_DIR"
chmod 640 "$PATTERNS_DIR"/*

# 4. Vérification
echo "4. Vérification des patterns..."
if [ -f "$PATTERNS_DIR/system" ] && \
   [ -f "$PATTERNS_DIR/application" ] && \
   [ -f "$PATTERNS_DIR/security" ] && \
   [ -f "$PATTERNS_DIR/metrics" ] && \
   [ -f "$PATTERNS_DIR/error" ]; then
    echo "✓ Tous les patterns sont configurés"
else
    echo "✗ Erreur: Certains patterns sont manquants"
    exit 1
fi

echo "=== Configuration des patterns Grok terminée ===" 
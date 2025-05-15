#!/bin/bash

# Configuration des variables
CERT_DIR="/opt/monitoring/certs"
OPENSSL_CNF="/etc/ssl/openssl.cnf"
VALIDITY_DAYS=365

# Fonction pour générer un certificat
generate_cert() {
    local name=$1
    local cn=$2
    local san=$3

    echo "Génération du certificat pour $name..."
    
    # Créer le répertoire si nécessaire
    mkdir -p "$CERT_DIR"
    
    # Générer la clé privée
    openssl genrsa -out "$CERT_DIR/$name.key" 2048
    
    # Générer la demande de signature (CSR)
    if [ -n "$san" ]; then
        # Créer un fichier de configuration temporaire avec SAN
        cat > "$CERT_DIR/$name.cnf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = FR
ST = Ile-de-France
L = Paris
O = Monitoring
OU = IT
CN = $cn

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = $san
EOF
        openssl req -new -key "$CERT_DIR/$name.key" \
            -out "$CERT_DIR/$name.csr" \
            -config "$CERT_DIR/$name.cnf"
    else
        openssl req -new -key "$CERT_DIR/$name.key" \
            -out "$CERT_DIR/$name.csr" \
            -subj "/C=FR/ST=Ile-de-France/L=Paris/O=Monitoring/OU=IT/CN=$cn"
    fi
    
    # Signer le certificat avec l'AC
    openssl x509 -req -in "$CERT_DIR/$name.csr" \
        -CA "$CERT_DIR/ca.crt" \
        -CAkey "$CERT_DIR/ca.key" \
        -CAcreateserial \
        -out "$CERT_DIR/$name.crt" \
        -days $VALIDITY_DAYS \
        -sha256 \
        -extfile "$CERT_DIR/$name.cnf" \
        -extensions v3_req
    
    # Nettoyer les fichiers temporaires
    rm -f "$CERT_DIR/$name.csr" "$CERT_DIR/$name.cnf"
    
    if [ $? -eq 0 ]; then
        echo "✓ Certificat pour $name généré avec succès"
        return 0
    else
        echo "✗ Erreur lors de la génération du certificat pour $name"
        return 1
    fi
}

# 1. Générer l'Autorité de Certification (AC)
echo "1. Génération de l'Autorité de Certification..."
mkdir -p "$CERT_DIR"

# Générer la clé privée de l'AC
openssl genrsa -out "$CERT_DIR/ca.key" 4096

# Générer le certificat de l'AC
openssl req -x509 -new -nodes \
    -key "$CERT_DIR/ca.key" \
    -sha256 -days $VALIDITY_DAYS \
    -out "$CERT_DIR/ca.crt" \
    -subj "/C=FR/ST=Ile-de-France/L=Paris/O=Monitoring/OU=IT/CN=Monitoring CA"

# 2. Générer les certificats pour chaque service
echo "2. Génération des certificats des services..."

# Elasticsearch
generate_cert "elasticsearch" "elasticsearch" "DNS:localhost,DNS:elasticsearch,IP:127.0.0.1"

# Kibana
generate_cert "kibana" "kibana" "DNS:localhost,DNS:kibana,IP:127.0.0.1"

# Logstash
generate_cert "logstash" "logstash" "DNS:localhost,DNS:logstash,IP:127.0.0.1"

# Filebeat
generate_cert "filebeat" "filebeat" "DNS:localhost,DNS:filebeat,IP:127.0.0.1"

# 3. Configurer les permissions
echo "3. Configuration des permissions..."
chmod 600 "$CERT_DIR"/*.key
chmod 644 "$CERT_DIR"/*.crt
chown -R root:root "$CERT_DIR"

# 4. Vérification
echo "4. Vérification des certificats..."
for cert in ca elasticsearch kibana logstash filebeat; do
    if [ -f "$CERT_DIR/$cert.crt" ] && [ -f "$CERT_DIR/$cert.key" ]; then
        echo "✓ Certificat $cert vérifié"
        # Afficher les informations du certificat
        echo "Informations du certificat $cert:"
        openssl x509 -in "$CERT_DIR/$cert.crt" -text -noout | grep "Subject:"
        openssl x509 -in "$CERT_DIR/$cert.crt" -text -noout | grep "Not After"
    else
        echo "✗ Erreur: Certificat $cert manquant"
        exit 1
    fi
done

echo "=== Génération des certificats terminée ===" 
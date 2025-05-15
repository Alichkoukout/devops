# Projet PFA - Application Mobile et Backend

Ce projet est composé d'une application mobile React Native (frontend) et d'un backend Spring Boot.

## Structure du Projet

```
.
├── frontendPfa/          # Application React Native
└── backendpfa/          # Backend Spring Boot
```

## Prérequis

### Frontend
- Node.js (v14 ou supérieur)
- npm ou yarn
- Expo CLI
- React Native development environment

### Backend
- Java JDK 17 ou supérieur
- Maven
- PostgreSQL

## Installation et Démarrage

### Frontend

1. Naviguer vers le dossier frontend :
```bash
cd frontendPfa
```

2. Installer les dépendances :
```bash
npm install
```

3. Démarrer l'application :
```bash
npm start
```

### Backend

1. Naviguer vers le dossier backend :
```bash
cd backendpfa
```

2. Installer les dépendances Maven :
```bash
./mvnw install
```

3. Démarrer l'application :
```bash
./mvnw spring-boot:run
```

## Tests

### Frontend
```bash
cd frontendPfa
npm test
```

### Backend
```bash
cd backendpfa
./mvnw test
```

## Déploiement

### Frontend
L'application frontend peut être déployée sur :
- Expo
- App Store (iOS)
- Google Play Store (Android)

### Backend
Le backend peut être déployé sur :
- Heroku
- AWS
- Google Cloud Platform

## Contribution

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails. 
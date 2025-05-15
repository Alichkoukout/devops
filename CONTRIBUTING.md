# Guide de Contribution

## Comment Contribuer

### 1. Prérequis
- Node.js (v14+) pour le frontend
- Java JDK 17+ pour le backend
- Docker et Docker Compose
- Git

### 2. Installation

#### Frontend
```bash
cd frontendPfa
npm install
```

#### Backend
```bash
cd backendpfa
./mvnw install
```

### 3. Processus de Développement

1. **Créer une branche**
   ```bash
   git checkout -b feature/nom-de-la-fonctionnalite
   ```

2. **Développer**
   - Suivre les conventions de code
   - Écrire des tests
   - Documenter les changements

3. **Tester**
   ```bash
   # Frontend
   cd frontendPfa
   npm test

   # Backend
   cd backendpfa
   ./mvnw test
   ```

4. **Commit**
   ```bash
   git commit -m "feat: description de la fonctionnalité"
   ```

5. **Push**
   ```bash
   git push origin feature/nom-de-la-fonctionnalite
   ```

6. **Pull Request**
   - Créer une PR sur GitHub
   - Décrire les changements
   - Attendre la review

### 4. Conventions de Code

#### Frontend (React Native)
- Utiliser TypeScript
- Suivre les conventions ESLint
- Utiliser les hooks React
- Écrire des composants réutilisables

#### Backend (Spring Boot)
- Suivre les conventions Java
- Utiliser les annotations Spring
- Documenter les APIs avec Swagger
- Écrire des tests unitaires

### 5. Tests

#### Frontend
- Tests unitaires avec Jest
- Tests de composants avec React Testing Library
- Tests E2E avec Detox

#### Backend
- Tests unitaires avec JUnit
- Tests d'intégration
- Tests de performance

### 6. Documentation

- Documenter les nouvelles fonctionnalités
- Mettre à jour l'API si nécessaire
- Ajouter des commentaires pour le code complexe

### 7. Review Process

1. Code review par au moins un autre développeur
2. Tests passés
3. Documentation à jour
4. Conformité aux conventions

### 8. Déploiement

- Les changements sont déployés automatiquement via CI/CD
- Tests automatisés avant déploiement
- Monitoring après déploiement

## Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement
- Consulter la documentation 
# SonarQube Setup

## sonar-project.properties
```properties
sonar.projectKey=devsecops-nodejs-azure
sonar.projectName=NodeJS-DevSecOps-Azure
sonar.sources=.
sonar.exclusions=**/node_modules/**,**/coverage/**,**/*.spec.js,**/*.test.js
sonar.sourceEncoding=UTF-8
```

## Quality Gate Recommendation
- Block on new critical vulnerabilities
- Block on code smells over agreed threshold
- Enforce minimum maintainability and reliability scores

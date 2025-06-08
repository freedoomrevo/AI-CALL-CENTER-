# 🔍 SonarCloud Setup Guide

This guide will help you set up SonarCloud integration for the Aetherium project to enable automated code quality analysis.

## 🚀 Quick Setup

### 1. **Create SonarCloud Account**

1. Go to [SonarCloud.io](https://sonarcloud.io)
2. Sign up with your GitHub account
3. Import your GitHub organization/repository

### 2. **Configure SonarCloud Project**

1. **Import Repository:**
   - Click "+" → "Analyze new project"
   - Select your GitHub repository: `Asilbekov/Ozodbek-`
   - Choose "With GitHub Actions"

2. **Project Configuration:**
   - **Project Key**: `Asilbekov_Ozodbek-`
   - **Organization**: `asilbekov` (or your organization)
   - **Project Name**: `Aetherium`

### 3. **Generate SonarCloud Token**

1. Go to **My Account** → **Security**
2. Generate a new token:
   - **Name**: `Aetherium-GitHub-Actions`
   - **Type**: `User Token`
   - **Expiration**: `No expiration` (or 1 year)
3. **Copy the token** (you'll need it for GitHub secrets)

### 4. **Add GitHub Secret**

1. Go to your GitHub repository: `https://github.com/Asilbekov/Ozodbek-`
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the secret:
   - **Name**: `SONAR_TOKEN`
   - **Value**: `[paste your SonarCloud token here]`

## 📋 Project Configuration

The project is already configured with `sonar-project.properties`:

```properties
# SonarCloud Configuration
sonar.projectKey=Asilbekov_Ozodbek-
sonar.organization=asilbekov

# Project Information
sonar.projectName=Aetherium
sonar.projectVersion=1.0.0

# Source Code Configuration
sonar.sources=backend,frontend/src
sonar.tests=backend/tests,frontend/src/__tests__

# Coverage Reports
sonar.python.coverage.reportPaths=backend/coverage.xml
sonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info
```

## 🚨 **IMMEDIATE FIX for Current Error**

The error you're seeing:
```
Failed to query JRE metadata: . Please check the property sonar.token or the environment variable SONAR_TOKEN.
```

**To fix this RIGHT NOW:**

1. **Go to GitHub Repository Settings:**
   ```
   https://github.com/Asilbekov/Ozodbek-/settings/secrets/actions
   ```

2. **Add the SONAR_TOKEN secret:**
   - Click "New repository secret"
   - Name: `SONAR_TOKEN`
   - Value: `[Your SonarCloud token]`

3. **If you don't have a SonarCloud token yet:**
   - Go to https://sonarcloud.io
   - Sign up with GitHub
   - Go to My Account → Security → Generate Token
   - Copy the token and add it to GitHub secrets

4. **Alternative: Disable SonarCloud temporarily:**
   - Comment out the SonarCloud step in `.github/workflows/ci.yml`
   - Or add condition: `if: env.SONAR_TOKEN != ''`

## 🔧 GitHub Actions Integration

The CI workflow includes SonarCloud analysis:

```yaml
# .github/workflows/ci.yml
code-quality:
  runs-on: ubuntu-latest
  needs: [backend-tests, frontend-tests]
  
  steps:
  - name: SonarCloud Scan
    uses: SonarSource/sonarcloud-github-action@master
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## 🎯 What SonarCloud Analyzes

### **Code Quality Metrics:**
- **Bugs**: Potential runtime errors
- **Vulnerabilities**: Security issues
- **Code Smells**: Maintainability issues
- **Coverage**: Test coverage percentage
- **Duplications**: Code duplication percentage

### **Languages Supported:**
- **Python**: Backend API code
- **JavaScript/TypeScript**: Frontend React code
- **HTML/CSS**: Frontend templates and styles

## 🚨 Troubleshooting

### **Error: "Failed to query JRE metadata"**
```bash
ERROR: Please check the property sonar.token or the environment variable SONAR_TOKEN.
```

**Solution:**
1. ✅ Add `SONAR_TOKEN` to GitHub repository secrets
2. ✅ Verify token is valid and not expired
3. ✅ Ensure token has proper permissions

### **Quick Fix - Disable SonarCloud Temporarily:**

If you want to disable SonarCloud for now, update the workflow:

```yaml
- name: SonarCloud Scan
  uses: SonarSource/sonarcloud-github-action@master
  if: env.SONAR_TOKEN != ''  # Only run if token exists
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## 📊 SonarCloud Dashboard

After setup, access your dashboard at:
```
https://sonarcloud.io/project/overview?id=Asilbekov_Ozodbek-
```

## 🎨 Badge Integration

Add SonarCloud badges to your README:

```markdown
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Asilbekov_Ozodbek-&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Asilbekov_Ozodbek-)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=Asilbekov_Ozodbek-&metric=coverage)](https://sonarcloud.io/summary/new_code?id=Asilbekov_Ozodbek-)
```

---

**Need immediate help?** The quickest solution is to add the `SONAR_TOKEN` secret to your GitHub repository settings!
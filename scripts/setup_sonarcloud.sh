#!/bin/bash
# SonarCloud Setup Helper Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║           🔍 SONARCLOUD SETUP HELPER 🔍                     ║"
echo "║                                                              ║"
echo "║         Aetherium Code Quality Analysis Setup               ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check if sonar-project.properties exists
if [[ -f "sonar-project.properties" ]]; then
    echo -e "${GREEN}✅ sonar-project.properties found${NC}"
else
    echo -e "${RED}❌ sonar-project.properties not found${NC}"
    echo -e "${YELLOW}Creating sonar-project.properties...${NC}"
    
    cat > sonar-project.properties << 'EOF'
# SonarCloud Configuration for Aetherium Project
sonar.projectKey=Asilbekov_Ozodbek-
sonar.organization=asilbekov

# Project Information
sonar.projectName=Aetherium
sonar.projectVersion=1.0.0

# Source Code Configuration
sonar.sources=backend,frontend/src
sonar.tests=backend/tests,frontend/src/__tests__

# Language-specific settings
sonar.python.coverage.reportPaths=backend/coverage.xml
sonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info

# Exclusions
sonar.exclusions=**/node_modules/**,**/venv/**,**/__pycache__/**,**/migrations/**,**/static/**,**/dist/**,**/build/**

# Test Exclusions
sonar.test.exclusions=**/tests/**,**/*.test.js,**/*.test.ts,**/*.spec.js,**/*.spec.ts

# Coverage Exclusions
sonar.coverage.exclusions=**/tests/**,**/migrations/**,**/venv/**,**/node_modules/**,**/__pycache__/**

# Quality Gate
sonar.qualitygate.wait=true

# Additional settings
sonar.sourceEncoding=UTF-8
EOF
    echo -e "${GREEN}✅ Created sonar-project.properties${NC}"
fi

echo -e "\n${CYAN}📋 SonarCloud Setup Checklist:${NC}\n"

echo -e "${YELLOW}1. Create SonarCloud Account:${NC}"
echo "   🌐 Go to: https://sonarcloud.io"
echo "   🔑 Sign up with your GitHub account"
echo ""

echo -e "${YELLOW}2. Import Repository:${NC}"
echo "   ➕ Click '+' → 'Analyze new project'"
echo "   📁 Select: Asilbekov/Ozodbek-"
echo "   ⚙️  Choose: 'With GitHub Actions'"
echo ""

echo -e "${YELLOW}3. Generate Token:${NC}"
echo "   👤 Go to: My Account → Security"
echo "   🔑 Generate new token: 'Aetherium-GitHub-Actions'"
echo "   📋 Copy the token"
echo ""

echo -e "${YELLOW}4. Add GitHub Secret:${NC}"
echo "   🌐 Go to: https://github.com/Asilbekov/Ozodbek-/settings/secrets/actions"
echo "   ➕ Click: 'New repository secret'"
echo "   📝 Name: SONAR_TOKEN"
echo "   🔑 Value: [paste your token]"
echo ""

echo -e "${YELLOW}5. Project Configuration:${NC}"
echo "   🔑 Project Key: Asilbekov_Ozodbek-"
echo "   🏢 Organization: asilbekov"
echo "   📛 Project Name: Aetherium"
echo ""

# Check if SONAR_TOKEN is set (for local testing)
if [[ -n "${SONAR_TOKEN:-}" ]]; then
    echo -e "${GREEN}✅ SONAR_TOKEN environment variable is set${NC}"
    
    # Test SonarCloud connection
    echo -e "\n${CYAN}🔍 Testing SonarCloud connection...${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s -u "$SONAR_TOKEN:" "https://sonarcloud.io/api/authentication/validate" || echo "error")
        if [[ "$response" == *"valid"* ]]; then
            echo -e "${GREEN}✅ SonarCloud token is valid${NC}"
        else
            echo -e "${RED}❌ SonarCloud token validation failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  curl not available, skipping token validation${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  SONAR_TOKEN not set in environment${NC}"
    echo -e "   For local testing, export SONAR_TOKEN=your_token"
fi

echo -e "\n${CYAN}🚀 Next Steps:${NC}"
echo "1. Complete the SonarCloud setup above"
echo "2. Push changes to trigger GitHub Actions"
echo "3. Check SonarCloud dashboard for analysis results"
echo "4. Monitor code quality metrics and coverage"

echo -e "\n${CYAN}📚 Documentation:${NC}"
echo "📖 Setup Guide: docs/SONARCLOUD_SETUP.md"
echo "🌐 SonarCloud Docs: https://docs.sonarcloud.io/"
echo "🔧 GitHub Actions: https://github.com/SonarSource/sonarcloud-github-action"

echo -e "\n${GREEN}✅ SonarCloud setup helper completed!${NC}"
echo -e "${CYAN}💡 Remember to add the SONAR_TOKEN secret to GitHub!${NC}"
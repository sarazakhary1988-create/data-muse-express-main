#!/bin/bash

# MANUS 1.6 MAX - Automated GitHub & Supabase Deployment
# Deploy in 15 minutes with interactive prompts

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     MANUS 1.6 MAX - Automated Deployment Script               ║"
echo "║     GitHub + Supabase Deployment (15 minutes)                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Phase 1: Gather Information
echo -e "${BLUE}[PHASE 1/6] Gathering Configuration${NC}"
echo ""

read -p "GitHub Username: " GITHUB_USER
read -p "Repository Name (default: data-muse-express-main): " REPO_NAME
REPO_NAME=${REPO_NAME:-data-muse-express-main}

read -p "Supabase Project ID: " SUPABASE_PROJECT_ID
read -p "Supabase Project URL (https://xxx.supabase.co): " SUPABASE_URL

echo ""
echo "${YELLOW}API Keys (enter to skip optional ones):${NC}"
read -sp "ANTHROPIC_API_KEY (Claude): " ANTHROPIC_API_KEY
echo ""
read -sp "OPENAI_API_KEY (GPT-4o): " OPENAI_API_KEY
echo ""
read -sp "GOOGLE_API_KEY (Gemini): " GOOGLE_API_KEY
echo ""
read -sp "TOGETHER_API_KEY (Llama/Qwen): " TOGETHER_API_KEY
echo ""

read -sp "Supabase Anon Key: " SUPABASE_ANON_KEY
echo ""
read -sp "Supabase Service Role Key: " SUPABASE_SERVICE_ROLE_KEY
echo ""

echo -e "${GREEN}✓ Configuration gathered${NC}"
echo ""

# Phase 2: Initialize Git
echo -e "${BLUE}[PHASE 2/6] Initializing Git Repository${NC}"
if [ ! -d .git ]; then
  git init
  git config user.name "Deployment Bot"
  git config user.email "deploy@manus.ai"
  echo -e "${GREEN}✓ Git initialized${NC}"
else
  echo -e "${GREEN}✓ Git already initialized${NC}"
fi
echo ""

# Phase 3: Create GitHub Remote
echo -e "${BLUE}[PHASE 3/6] Setting Up GitHub Remote${NC}"
GITHUB_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
git remote remove origin 2>/dev/null || true
git remote add origin "$GITHUB_URL"
echo -e "${GREEN}✓ GitHub remote: $GITHUB_URL${NC}"
echo ""

# Phase 4: Stage and Commit
echo -e "${BLUE}[PHASE 4/6] Committing Files to Git${NC}"
git add .
git commit -m "Deploy: MANUS 1.6 MAX - Complete autonomous AI agent system" --allow-empty
echo -e "${GREEN}✓ Files committed${NC}"
echo ""

# Phase 5: Push to GitHub
echo -e "${BLUE}[PHASE 5/6] Pushing to GitHub${NC}"
echo -e "${YELLOW}Note: You may be prompted for authentication${NC}"
if git push -u origin main 2>&1; then
  echo -e "${GREEN}✓ Pushed to GitHub successfully${NC}"
else
  echo -e "${RED}✗ GitHub push failed${NC}"
  echo "Make sure:"
  echo "  1. Repository exists: https://github.com/${GITHUB_USER}/${REPO_NAME}"
  echo "  2. You have push access"
  echo "  3. SSH or HTTPS credentials are configured"
  exit 1
fi
echo ""

# Phase 6: Configure Secrets in GitHub (if gh CLI available)
echo -e "${BLUE}[PHASE 6/6] Configuring GitHub Secrets${NC}"
if command -v gh &> /dev/null; then
  echo -e "${YELLOW}GitHub CLI detected. Setting secrets...${NC}"
  
  [ -n "$ANTHROPIC_API_KEY" ] && gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY" -R "${GITHUB_USER}/${REPO_NAME}" || true
  [ -n "$OPENAI_API_KEY" ] && gh secret set OPENAI_API_KEY -b "$OPENAI_API_KEY" -R "${GITHUB_USER}/${REPO_NAME}" || true
  [ -n "$GOOGLE_API_KEY" ] && gh secret set GOOGLE_API_KEY -b "$GOOGLE_API_KEY" -R "${GITHUB_USER}/${REPO_NAME}" || true
  [ -n "$TOGETHER_API_KEY" ] && gh secret set TOGETHER_API_KEY -b "$TOGETHER_API_KEY" -R "${GITHUB_USER}/${REPO_NAME}" || true
  
  gh secret set SUPABASE_PROJECT_ID -b "$SUPABASE_PROJECT_ID" -R "${GITHUB_USER}/${REPO_NAME}"
  gh secret set SUPABASE_URL -b "$SUPABASE_URL" -R "${GITHUB_USER}/${REPO_NAME}"
  gh secret set SUPABASE_ANON_KEY -b "$SUPABASE_ANON_KEY" -R "${GITHUB_USER}/${REPO_NAME}"
  gh secret set SUPABASE_SERVICE_ROLE_KEY -b "$SUPABASE_SERVICE_ROLE_KEY" -R "${GITHUB_USER}/${REPO_NAME}"
  
  echo -e "${GREEN}✓ GitHub secrets configured${NC}"
else
  echo -e "${YELLOW}GitHub CLI not found. Set secrets manually:${NC}"
  echo -e "${YELLOW}Visit: https://github.com/${GITHUB_USER}/${REPO_NAME}/settings/secrets/actions${NC}"
  echo -e "${YELLOW}Create these secrets:${NC}"
  echo "  - ANTHROPIC_API_KEY"
  echo "  - OPENAI_API_KEY"
  echo "  - GOOGLE_API_KEY"
  echo "  - TOGETHER_API_KEY"
  echo "  - SUPABASE_PROJECT_ID"
  echo "  - SUPABASE_URL"
  echo "  - SUPABASE_ANON_KEY"
  echo "  - SUPABASE_SERVICE_ROLE_KEY"
fi
echo ""

# Completion Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo -e "║${GREEN}   ✓ DEPLOYMENT COMPLETE${NC}                                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Repository:${NC} https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Visit: https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo "  2. Go to Settings → Secrets → Actions"
echo "  3. Verify all secrets are set"
echo "  4. Deploy to Supabase:"
echo "     ${BLUE}supabase projects list${NC}"
echo "     ${BLUE}supabase link --project-ref ${SUPABASE_PROJECT_ID}${NC}"
echo "     ${BLUE}supabase db push${NC}"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo "  - Full Guide: README.md"
echo "  - Quick Start: START_HERE_DEPLOYMENT.md"
echo "  - Detailed: DEPLOYMENT_GUIDE_COMPLETE.md"
echo ""
echo "Deployment started at: $(date)"
echo "Repository: $GITHUB_URL"
echo ""

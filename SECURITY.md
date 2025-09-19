# Security Configuration Guide

## Overview
This document outlines the security best practices and configuration for the Kansyl iOS application.

## API Key Management

### Current Setup
The application uses DeepSeek API for AI-powered receipt scanning. API keys are managed through:

1. **Development**: Use `APIConfig.swift` (gitignored) for local development
2. **Production**: Use `Config.plist` (gitignored) for production builds

### Security Rules

#### NEVER Commit These Files:
- `Config.plist` - Contains production API keys
- `APIConfig.swift` - Contains development API keys  
- `.env` files - Contains environment variables
- Any file with actual API keys or secrets

#### ALWAYS Commit These Files:
- `Config.plist.example` - Template for configuration
- `APIConfig.swift.template` - Template for API configuration
- `.env.example` - Template for environment variables

## Setting Up API Keys

### For Development:
1. Copy `kansyl/Config/APIConfig.swift.template` to `kansyl/Config/APIConfig.swift`
2. Replace placeholder values with your actual API keys
3. Ensure `APIConfig.swift` is in `.gitignore`

### For Production:
1. Copy `kansyl/Config/Config.plist.example` to `kansyl/Config/Config.plist`
2. Replace placeholder values with your production API keys
3. Ensure `Config.plist` is in `.gitignore`

## API Endpoints

### Public Endpoints (Safe to commit):
- DeepSeek API: `https://api.deepseek.com/v1`
- Currency Exchange API: `https://api.exchangerate-api.com/v4/latest/USD`

These are public API endpoints and safe to include in the codebase.

## Gitignore Configuration

The `.gitignore` file is configured to exclude:
- All `*.plist` files except examples and Info.plist
- API configuration files
- Environment files
- Authentication managers with sensitive logic

## Security Checklist

Before committing code:
- [ ] No API keys in source files
- [ ] No passwords or secrets in comments
- [ ] Config files use templates/examples
- [ ] Sensitive files are gitignored
- [ ] API keys load from external config

Before pushing to GitHub:
- [ ] Run `git status` to verify no sensitive files
- [ ] Check diff for accidental key exposure
- [ ] Ensure production keys are never committed

## Rate Limiting and Usage Protection

The app implements several security measures:
1. **Rate limiting**: API calls are throttled to prevent abuse
2. **Usage tracking**: Production scans are limited per user
3. **Error handling**: API keys are validated before use

## Reporting Security Issues

If you discover a security vulnerability:
1. DO NOT create a public GitHub issue
2. Contact the maintainers directly
3. Provide details about the vulnerability
4. Allow time for a fix before disclosure

## Additional Resources

- [DeepSeek API Documentation](https://platform.deepseek.com)
- [iOS Security Best Practices](https://developer.apple.com/security/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
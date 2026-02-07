# GitHub Actions Workflows

This directory contains GitHub Actions workflows for CI/CD and automation.

## Workflows

### CI (`ci.yml`)
Runs on every push and pull request to `main` and `develop` branches.

**Jobs:**
- **Test**: Analyzes the code with `flutter analyze`
- **Build**: Builds release APKs for Android

### Release (`release.yml`)
Handles the release process when a new tag is created.

### Crowdin Sync (`crowdin.yml`)
Manages synchronization with Crowdin for translations.

**Triggers:**
- **Push to main** (when `lib/l10n/app_en.arb` changes): Uploads source strings to Crowdin
- **Manual trigger**: Can be run manually from the Actions tab to download translations
- **Weekly schedule**: Automatically downloads new translations every Sunday

**Required Secrets:**
- `CROWDIN_PROJECT_ID`: Your Crowdin project ID (e.g., "florid")
- `CROWDIN_PERSONAL_TOKEN`: Personal access token from Crowdin account settings
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

**Setup Instructions:**

1. **Get Crowdin credentials:**
   - Log in to [Crowdin](https://crowdin.com)
   - Go to Account Settings → API
   - Generate a Personal Access Token
   - Note your project ID (visible in project settings or URL)

2. **Add secrets to GitHub:**
   - Go to repository Settings → Secrets and variables → Actions
   - Add `CROWDIN_PROJECT_ID` with your project ID
   - Add `CROWDIN_PERSONAL_TOKEN` with your token

3. **Test the workflow:**
   - Go to Actions tab
   - Select "Crowdin Sync" workflow
   - Click "Run workflow"
   - Check if translations sync correctly

## Workflow Behavior

### Source String Updates
When you modify `lib/l10n/app_en.arb` and push to main:
1. Workflow automatically uploads the new/modified strings to Crowdin
2. Translators can immediately start working on new strings

### Translation Downloads
When you manually trigger or on weekly schedule:
1. Workflow downloads latest translations from Crowdin
2. Creates a new branch `l10n_crowdin`
3. Generates Flutter localization files with `flutter gen-l10n`
4. Opens a pull request with the label `localization`
5. Review and merge the PR to update translations

## Local Testing

To test Crowdin integration locally:

```bash
# Install Crowdin CLI
npm install -g @crowdin/cli

# Upload sources
crowdin upload sources --token YOUR_TOKEN --project-id YOUR_PROJECT_ID

# Download translations
crowdin download --token YOUR_TOKEN --project-id YOUR_PROJECT_ID

# Generate Flutter localization files
flutter gen-l10n
```

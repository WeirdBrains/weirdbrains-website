# weirdbrains.ai

Official website for Weird Brains — Flutter Web, hosted on GCP Cloud Run.

## Stack

- Flutter Web (Dart)
- GCP Cloud Run (`mandible-production` project, `us-central1`)
- Cloud Build CI/CD
- Custom domain: weirdbrains.ai

## Local development

```bash
flutter pub get
flutter run -d chrome
```

## Deploy

Push to `main` → Cloud Build triggers → Cloud Run deploy.
Manual deploy: `gcloud run deploy weirdbrains-website --image gcr.io/mandible-production/weirdbrains-website:latest --region us-central1`

## DNS

weirdbrains.ai → GoDaddy DNS → CNAME → Cloud Run domain
Managed at: GoDaddy (account: Zack Mohorn)

# WEI-21: weirdbrains.ai — Flutter Web Migration Plan
**Created:** 2026-03-28  
**Owner:** Gilbert (WEI PM)  
**Status:** Planning

---

## Current State Audit

| Property | Current |
|---|---|
| Host | GoDaddy Website Builder 8.0 |
| DNS | GoDaddy nameservers (ns21/ns22.domaincontrol.com) |
| IPs | 76.223.105.230, 13.248.243.5 (AWS Global Accelerator) |
| Content | "Launching Soon" placeholder, video background, Playfair Display font |
| Complexity | Minimal — clean-room build, no content to migrate |

**Assessment:** No migration complexity. Pure greenfield Flutter Web build + Cloud Run deploy.

---

## Target Architecture

```
weirdbrains.ai
    │
    ├── DNS: GoDaddy → CNAME → Cloud Run custom domain
    │
    └── GCP Cloud Run (mandible-production project)
            └── nginx container serving Flutter Web build
                    └── /web/ (flutter build web output)
```

**GCP project:** `mandible-production` (shared infrastructure, consolidated billing)  
**Region:** us-central1 (consistent with Mandible)  
**Deployment:** Cloud Build trigger → Cloud Run on push to `main`

---

## Implementation Steps

### Phase 1 — Flutter Web App (MandibleDev)
1. `flutter create weirdbrains_website --template=app --platforms=web`
2. Implement landing page:
   - Hero: Weird Brains name/logo + tagline
   - Portfolio section: Mandible, WickHackers, Myelin/GYRI cards
   - Contact/CTA section
3. `flutter build web --release --base-href /`
4. Create `Dockerfile` (nginx serving `/build/web`)
5. Add `.cursor/bugbot.json` rules

### Phase 2 — GCP Setup (Gilbert / board)
1. Create Cloud Run service `weirdbrains-website` in `mandible-production`
2. Cloud Build trigger: `WeirdBrains/weirdbrains-website` main branch
3. Map custom domain `weirdbrains.ai` in Cloud Run

### Phase 3 — DNS Cutover (Zack)
1. In GoDaddy DNS: add CNAME `weirdbrains.ai` → Cloud Run domain
2. Wait for propagation (~24h)
3. Cancel GoDaddy Website Builder subscription

---

## Dockerfile

```dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

Note: Cloud Run requires port 8080. Nginx config must listen on 8080.

---

## Cloud Build config (cloudbuild.yaml)

```yaml
steps:
  - name: 'ghcr.io/cirruslabs/flutter:stable'
    entrypoint: flutter
    args: ['build', 'web', '--release']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/mandible-production/weirdbrains-website:$COMMIT_SHA', '.']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/mandible-production/weirdbrains-website:$COMMIT_SHA']
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - run
      - deploy
      - weirdbrains-website
      - --image=gcr.io/mandible-production/weirdbrains-website:$COMMIT_SHA
      - --region=us-central1
      - --platform=managed
      - --allow-unauthenticated
```

---

## Content Brief for Landing Page

**Headline:** Weird Brains — AI ventures at the intersection of domain expertise and emerging technology  
**Tagline:** We build intelligent systems in dental, finance, and blockchain.

**Portfolio cards:**
- **Mandible** — AI-powered dental case platform (launching 2026)
- **WickHackers** — Algorithmic trading: Coinbase perps, Kalshi, prediction markets
- **Myelin/GYRI** — Rust L1 blockchain with usage-adaptive tokenomics

**Footer:** © 2026 Weird Brains | gilbert@weirdbrains.ai

---

## Board Actions Required (before Phase 2)
1. Approve GitHub repo creation: `WeirdBrains/weirdbrains-website`
2. Confirm Cloud Run deploy in `mandible-production` project (consistent with existing infra)
3. GoDaddy login for DNS cutover (Phase 3)

---

## Estimate
- MandibleDev build time: ~1 sprint (1-2 days)  
- GCP setup: ~30 min (Gilbert)  
- DNS propagation: ~24h  
- Total elapsed: ~3 days

# Deploying Twenty CRM on Render

This guide walks you through deploying Twenty CRM to [Render](https://render.com) using the included Blueprint (`render.yaml`).

---

## Architecture on Render

| Service | Type | Purpose |
|---------|------|---------|
| `twenty-server` | Web Service (Docker) | NestJS API + React frontend |
| `twenty-worker` | Background Worker (Docker) | BullMQ job processor |
| `twenty-db` | PostgreSQL 16 | Primary database |
| `twenty-redis` | Redis | Cache, queues, subscriptions |

---

## Prerequisites

- A [Render account](https://dashboard.render.com/register) (free to sign up)
- This repository pushed to GitHub (public or private)

---

## One-Click Deploy

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **New** > **Blueprint**
3. Connect your GitHub repository containing this code
4. Render will detect `render.yaml` and show all services to be created
5. Click **Apply** to deploy

Render will automatically:
- Build the Docker images
- Provision PostgreSQL 16 and Redis
- Wire up all environment variables
- Run database migrations on first boot

---

## Manual Setup (Alternative)

If you prefer to set up services individually:

### 1. Create PostgreSQL Database

- Go to **New** > **PostgreSQL**
- Name: `twenty-db`
- PostgreSQL version: **16**
- Plan: Starter (or higher for production)
- Note the **Internal Connection String**

### 2. Create Redis Instance

- Go to **New** > **Redis**
- Name: `twenty-redis`
- Maxmemory policy: **noeviction** (required!)
- Plan: Starter
- Note the **Internal Connection String**

### 3. Create Web Service (Server)

- Go to **New** > **Web Service**
- Connect your repo
- Environment: **Docker**
- Dockerfile Path: `packages/twenty-docker/twenty/Dockerfile`
- Docker Context: `.` (repo root)
- Docker Target: `twenty`
- Plan: Starter (1 GB RAM minimum)
- Add a **Disk**: mount at `/app/packages/twenty-server/.local-storage`, 1 GB

Set these environment variables:

| Variable | Value |
|----------|-------|
| `NODE_PORT` | `3000` |
| `SERVER_URL` | Your Render service URL (e.g. `https://twenty-server-xxxx.onrender.com`) |
| `PG_DATABASE_URL` | PostgreSQL internal connection string |
| `REDIS_URL` | Redis internal connection string |
| `ENCRYPTION_KEY` | Run `openssl rand -base64 32` to generate |
| `APP_SECRET` | Run `openssl rand -base64 32` to generate |
| `STORAGE_TYPE` | `local` |
| `DISABLE_DB_MIGRATIONS` | `false` |
| `DISABLE_CRON_JOBS_REGISTRATION` | `false` |

### 4. Create Background Worker

- Go to **New** > **Background Worker**
- Connect your repo
- Environment: **Docker**
- Dockerfile Path: `packages/twenty-docker/twenty/Dockerfile`
- Docker Context: `.` (repo root)
- Docker Target: `twenty-server`
- Docker Command: `node dist/queue-worker/queue-worker`
- Plan: Starter

Set these environment variables:

| Variable | Value |
|----------|-------|
| `SERVER_URL` | Same as the web service |
| `PG_DATABASE_URL` | Same PostgreSQL connection string |
| `REDIS_URL` | Same Redis connection string |
| `ENCRYPTION_KEY` | Same as the web service |
| `APP_SECRET` | Same as the web service |
| `STORAGE_TYPE` | `local` |
| `DISABLE_DB_MIGRATIONS` | `true` |
| `DISABLE_CRON_JOBS_REGISTRATION` | `true` |

---

## Post-Deployment

### First Login

Once deployed, visit your `SERVER_URL`. You'll be greeted with the Twenty onboarding flow to create your first workspace and admin account.

### Custom Domain

1. In Render Dashboard, go to your `twenty-server` service
2. Click **Settings** > **Custom Domains**
3. Add your domain and configure DNS as instructed
4. Update `SERVER_URL` env var to your custom domain

### File Storage (S3 — Optional)

For production, switch from local disk to S3-compatible storage:

| Variable | Value |
|----------|-------|
| `STORAGE_TYPE` | `s3` |
| `STORAGE_S3_REGION` | Your bucket region |
| `STORAGE_S3_NAME` | Bucket name |
| `STORAGE_S3_ENDPOINT` | S3 endpoint (for non-AWS providers) |
| `STORAGE_S3_ACCESS_KEY_ID` | Access key |
| `STORAGE_S3_SECRET_ACCESS_KEY` | Secret key |

### Email (Optional)

To enable email sending (invitations, notifications):

| Variable | Value |
|----------|-------|
| `EMAIL_FROM_ADDRESS` | `noreply@yourdomain.com` |
| `EMAIL_FROM_NAME` | `Twenty CRM` |
| `EMAIL_DRIVER` | `smtp` |
| `EMAIL_SMTP_HOST` | Your SMTP host |
| `EMAIL_SMTP_PORT` | `465` |
| `EMAIL_SMTP_USER` | SMTP username |
| `EMAIL_SMTP_PASSWORD` | SMTP password |

---

## Estimated Costs (Render)

| Resource | Plan | Approx. Cost |
|----------|------|-------------|
| Web Service (Starter) | 1 GB RAM | $7/month |
| Worker (Starter) | 1 GB RAM | $7/month |
| PostgreSQL (Starter) | 1 GB RAM | $7/month |
| Redis (Starter) | 25 MB | $0/month (free tier) |
| Disk (1 GB) | — | $0.25/month |
| **Total** | | **~$21/month** |

> Upgrade to Standard plans for production workloads with more RAM and CPU.

---

## Troubleshooting

### Build fails with out-of-memory

The frontend build requires significant memory. If building fails:
- Upgrade to a Standard plan (2 GB+ RAM) during initial build
- Or pre-build the frontend locally and commit the `packages/twenty-front/build/` directory

### Database migrations fail

- Check the `twenty-server` logs in Render Dashboard
- Ensure `PG_DATABASE_URL` is correct and the database is accessible
- Verify `DISABLE_DB_MIGRATIONS` is set to `false` on the server (not the worker)

### Redis connection errors

- Ensure the Redis `maxmemory-policy` is set to `noeviction`
- Verify `REDIS_URL` uses the **internal** connection string (not external)

### Health check fails

The server exposes `/healthz`. If health checks fail:
- Allow 2-3 minutes for the first boot (migrations run on startup)
- Check logs for startup errors
- Ensure all required env vars are set

---

## Updating

To deploy updates:
1. Push changes to your connected branch
2. Render will automatically rebuild and redeploy
3. Database migrations run automatically on server startup

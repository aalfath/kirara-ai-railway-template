[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/kirara-ai?utm_medium=integration&utm_source=button&utm_campaign=kirara-ai)

# Kirara AI on Railway

One-click [Railway](https://railway.com) template for **[Kirara AI](https://github.com/lss233/kirara-ai)** **v3.2.1**. Kirara AI is a multimodal AI chatbot with a visual workflow editor and a web admin panel. It connects LLMs (OpenAI, DeepSeek, Gemini, Claude, Ollama, OpenRouter and other OpenAI-compatible APIs) to chat platforms: Telegram, QQ, WeCom and an HTTP API.

## What it deploys

One service, **Kirara AI**, built from this repo's `Dockerfile`:

- the Kirara AI server, release v3.2.1 (commit `36249e4a`; the package reports itself as `3.3.0a2`), built with upstream's Dockerfile recipe on `python:3.11.18-slim-bookworm` (pinned by digest);
- the web admin panel (`kirara-ai-webui` 0.1.0), served on the same port;
- a volume at `/app/data` that holds the SQLite database, config, chat memory, media, workflows, dispatch rules and the admin password hash.

No other services are needed. The health check is `/`.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `LLM_API_KEY` | *(you enter it)* | API key for your LLM provider, e.g. an OpenAI key from https://platform.openai.com/api-keys. |
| `LLM_BASE_URL` | `https://api.openai.com/v1` | Any OpenAI-compatible endpoint (DeepSeek `https://api.deepseek.com/v1`, OpenRouter `https://openrouter.ai/api/v1`, …). |
| `LLM_MODEL` | `gpt-4o-mini` | Model name, or several separated by commas. The first one becomes the default. |
| `ADMIN_PASSWORD` | generated | Password for the web admin panel. Set once on first boot. Change it later in the panel. |
| `HTTP_API_KEY` | generated | Bearer token for the built-in HTTP chat API (`POST /v1/chat`). Leave it empty to turn the API off. |
| `PORT` | `8080` | Port the app listens on. |

On every boot the start script writes the LLM backend named `railway-default` and the HTTP API adapter named `railway-http-api` into `data/config.yaml` from these variables. Backends, chat platforms and workflows that you add in the panel are kept.

## After deploy

1. Open the public URL and log in with `ADMIN_PASSWORD` (see the service's **Variables** tab).
2. Under **IM** (chat platforms), add a Telegram bot token or another platform. Under **Models**, add more providers if you like.
3. Try the HTTP API:
   ```sh
   curl -X POST https://YOUR-DOMAIN/v1/chat \
     -H "Authorization: Bearer YOUR-HTTP_API_KEY" -H "Content-Type: application/json" \
     -d '{"session_id":"friend-me","username":"me","message":"Hello!"}'
   ```

## Notes

- **Memory:** runs in 0.5 GB RAM (Railway Free/Trial). Measured on Railway at 0.5 GB / 1 vCPU: about 165 MB after chats, no OOM kills. Plugins that render images (wkhtmltopdf) or process voice (ffmpeg) need more.
- **Not included:** the bundled frp tunnel (Railway already gives a public URL) and Docker-based code sandboxes (Railway has no Docker-in-Docker).
- **Updates:** use Railway's "update available" notice, not the panel's built-in updater. An update installed from the panel goes into the venv on the volume and hides later template updates.
- A crash makes the start script exit non-zero, so Railway's `ON_FAILURE` restart policy brings the service back.

## How updates reach you

This template builds from this GitHub repo. When we bump Kirara AI here (`Dockerfile` pin and `constraints.txt`) and merge to `main`, Railway shows an "update available" notice on your project, and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first. Breaking changes are listed first.

## Licence

Kirara AI is AGPL-3.0 ([upstream](https://github.com/lss233/kirara-ai)). This wrapper (Dockerfile and scripts) is published under the same licence.

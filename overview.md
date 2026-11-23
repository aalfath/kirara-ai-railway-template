# Deploy and Host Kirara AI on Railway

Kirara AI is an open-source (AGPL-3.0) multimodal AI chatbot server. It connects language models such as OpenAI, DeepSeek, Gemini, Claude, Ollama and other OpenAI-compatible APIs to chat platforms: Telegram, QQ, WeCom and a plain HTTP API. You build its behaviour in a visual workflow editor, and it keeps per-user chat memory.

## About Hosting Kirara AI

This template runs Kirara AI v3.2.1 with its web admin panel as one service. Railway builds it from a public GitHub repo that pins the release commit and every Python dependency. A volume at `/app/data` holds the SQLite database, config, chat memory, media and workflows, so they survive redeploys and restarts. On first boot the panel is locked with a generated `ADMIN_PASSWORD`, and the HTTP chat API needs a generated `HTTP_API_KEY`. You only enter your LLM API key, plus a different base URL and model name if you don't use OpenAI. The service runs in 0.5 GB of RAM, about 165 MB measured while chatting.

## Common Use Cases

* A Telegram, QQ or WeCom group bot backed by GPT, DeepSeek or another LLM, with memory per user
* A private chat API (`POST /v1/chat`) that your own apps or scripts can call through one endpoint
* Building and testing chat workflows (prompts, memory, image generation, MCP tools) in a visual editor

## Dependencies for Kirara AI Hosting

* An API key for an LLM provider (OpenAI, or any OpenAI-compatible endpoint such as DeepSeek or OpenRouter)
* A bot token from each chat platform you want to connect (optional, added in the panel)

### Deployment Dependencies

* Kirara AI: https://github.com/lss233/kirara-ai
* Kirara AI docs: https://kirara-docs.app.lss233.com
* Template repo, with changelog: https://github.com/aalfath/kirara-ai-railway-template

### Implementation Details

The template deploys one service, **Kirara AI**: the bot server and the web admin panel on one port. Its volume is mounted at `/app/data`. The health check is `/`.

After deploy:

1. Open the public URL and log in with `ADMIN_PASSWORD`, which you can find in the service's Variables tab. Change it in the panel if you like.
2. Your model is already added as the `railway-default` backend. Add a Telegram, QQ or WeCom bot under **IM**, and more providers under **Models**.
3. Call the HTTP API:

```sh
curl -X POST https://YOUR-DOMAIN/v1/chat \
  -H "Authorization: Bearer YOUR-HTTP_API_KEY" -H "Content-Type: application/json" \
  -d '{"session_id":"friend-me","username":"me","message":"Hello!"}'
```

On every boot the variables `LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL` and `HTTP_API_KEY` rewrite only the `railway-default` backend and the `railway-http-api` adapter. Everything else you configure in the panel is kept. The bundled frp tunnel and Docker-based code sandboxes are left off, because Railway gives you a public URL and has no Docker-in-Docker.

**Updates:** when the template repo moves to a new Kirara AI release, Railway shows an "update available" notice on your project, and you apply it when you choose. Read the repo's CHANGELOG first. Don't use the panel's built-in updater: it installs into the volume and hides later template updates.

## Why Deploy Kirara AI on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Kirara AI on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->

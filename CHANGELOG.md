# Changelog

Each entry is one version of this Railway template. Breaking changes are listed first.

## 3.2.1-railway.1 (2026-11-23)

- First release: Kirara AI **v3.2.1** (release commit `36249e4a0aa8e3d8930acdfe4e14ec2be6484f63`; the package reports itself as `3.3.0a2`), web UI `kirara-ai-webui` 0.1.0.
- Built from upstream's Dockerfile recipe on `python:3.11.18-slim-bookworm` (pinned by digest), with checksums on the source and web UI downloads.
- Admin password set on first boot from the generated `ADMIN_PASSWORD`, so nobody else can claim the instance.
- LLM backend (`LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL`) and the HTTP chat API (`HTTP_API_KEY`) are written into `data/config.yaml` on each boot.
- All state on the `/app/data` volume; the start script exits non-zero on any unexpected stop so Railway restarts it.

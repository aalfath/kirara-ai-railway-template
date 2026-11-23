"""Write Railway variables into Kirara AI's data/config.yaml on every boot.

Only the entries this template owns are touched:
  - the LLM backend named "railway-default" (LLM_API_KEY, LLM_BASE_URL, LLM_MODEL)
  - the HTTP chat API named "railway-http-api" (HTTP_API_KEY)
  - defaults.llm_model and system.timezone, only if still on upstream's defaults
Anything you add or change in the web UI is kept.
"""
import os
import sys

from ruamel.yaml import YAML

PATH = "/app/data/config.yaml"
BACKEND = "railway-default"
IM = "railway-http-api"

yaml = YAML()
cfg = {}
if os.path.exists(PATH):
    with open(PATH, encoding="utf-8") as f:
        cfg = yaml.load(f) or {}

def env(name, default=""):
    v = os.environ.get(name, "")
    return v.strip() if v and v.strip() else default

api_key = env("LLM_API_KEY")
base_url = env("LLM_BASE_URL", "https://api.openai.com/v1").rstrip("/")
models = [m.strip() for m in env("LLM_MODEL", "gpt-4o-mini").split(",") if m.strip()]
http_key = env("HTTP_API_KEY")

# --- LLM backend -----------------------------------------------------------
llms = cfg.setdefault("llms", {})
backends = llms.setdefault("api_backends", []) or []
llms["api_backends"] = backends
backends[:] = [b for b in backends if b.get("name") != BACKEND]
if api_key:
    backends.insert(0, {
        "name": BACKEND,
        "adapter": "openai",
        "enable": True,
        "config": {"api_key": api_key, "api_base": base_url},
        "models": [{"id": m, "type": "llm", "ability": 14} for m in models],  # 14 = TextChat
    })
    print(f"[railway] LLM backend '{BACKEND}': {base_url} models={models}")
else:
    print("[railway] LLM_API_KEY is empty: no LLM backend configured from variables "
          "(add one in the web UI under Models, or set LLM_API_KEY).", file=sys.stderr)

defaults = cfg.setdefault("defaults", {})
if models and defaults.get("llm_model") in (None, "", "gemini-1.5-flash"):
    defaults["llm_model"] = models[0]

# --- HTTP chat API (http_legacy adapter, served on the same port) -----------
ims = cfg.setdefault("ims", []) or []
cfg["ims"] = ims
ims[:] = [i for i in ims if i.get("name") != IM]
if http_key:
    ims.append({"name": IM, "enable": True, "adapter": "http_legacy",
                "config": {"api_key": http_key}})
else:
    print("[railway] HTTP_API_KEY is empty: the /v1/chat and /v2/chat API is disabled.")

# --- system / web ---------------------------------------------------------------
system = cfg.setdefault("system", {})
tz = env("TZ", "UTC")
if system.get("timezone") in (None, "", "Asia/Shanghai") or os.environ.get("TZ"):
    system["timezone"] = tz
web = cfg.setdefault("web", {})
web["host"] = "0.0.0.0"
web["port"] = int(env("PORT", "8080"))
# bundled frp tunnel is never needed on Railway
frpc = cfg.setdefault("frpc", {})
frpc["enable"] = False

tmp = PATH + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    yaml.dump(cfg, f)
os.replace(tmp, PATH)

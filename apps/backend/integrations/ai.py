"""AI inference — OpenAI-compatible HTTP adapter (fail-closed)."""
from __future__ import annotations

from django.conf import settings
from django.utils import timezone

from .http_client import IntegrationHttpClient, IntegrationHttpError


class AiAdapterNotConfigured(RuntimeError):
    pass


class OpenAICompatibleInferenceAdapter:
    """Calls an OpenAI-compatible /chat/completions (or /v1/responses) endpoint.

    Configure via TAIFA_AI_PROVIDER:
      {
        "base_url": "https://api.openai.com/v1",
        "api_key": "...",
        "model": "gpt-4o-mini",
        "path": "/chat/completions"
      }
    """

    def __init__(self, model_code: str | None = None):
        cfg = getattr(settings, "TAIFA_AI_PROVIDER", None) or {}
        base_url = (cfg.get("base_url") or "").strip()
        api_key = (cfg.get("api_key") or "").strip()
        if not base_url or not api_key:
            raise AiAdapterNotConfigured(
                "AI provider is not configured (set TAIFA_AI_PROVIDER_JSON with base_url + api_key)"
            )
        self.model = model_code or cfg.get("model") or "gpt-4o-mini"
        self._path = cfg.get("path", "/chat/completions")
        self._client = IntegrationHttpClient(
            integration="ai.openai_compatible",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 45)),
            max_retries=int(cfg.get("max_retries", 2)),
            default_headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            verify_tls=bool(cfg.get("verify_tls", True)),
        )

    def infer(self, *, capability_code: str, payload: dict, modality: str = "text") -> dict:
        text = str(
            payload.get("text")
            or payload.get("query")
            or payload.get("prompt")
            or payload.get("hint")
            or ""
        )
        system = (
            f"You are Taifa AI capability '{capability_code}' (modality={modality}). "
            "Respond with concise, actionable JSON when possible. Never invent regulated facts."
        )
        body = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": text or str(payload)},
            ],
            "temperature": float(payload.get("temperature", 0.2)),
        }
        try:
            resp = self._client.request(
                "POST",
                self._path,
                operation=f"infer.{capability_code}",
                json=body,
            )
            data = resp.json()
        except IntegrationHttpError as exc:
            raise RuntimeError(f"AI inference failed: {exc}") from exc

        content = ""
        try:
            content = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            content = str(data.get("output") or data)

        return {
            "reply": content,
            "capability": capability_code,
            "modality": modality,
            "model": self.model,
            "generated_at": timezone.now().isoformat(),
            "raw_provider": {
                "id": data.get("id"),
                "usage": data.get("usage"),
            },
            "provider": "openai_compatible",
        }

    def invoke(self, *, capability_code: str, payload: dict) -> dict:
        """Ecosystem AiAdapter protocol."""
        result = self.infer(capability_code=capability_code, payload=payload)
        return {
            "capability": capability_code,
            "generated_at": result["generated_at"],
            "result": result,
            "model_version": self.model,
            "confidence_e4": 7000,
            "reasoning_summary": "openai_compatible",
            "evidence": [],
        }

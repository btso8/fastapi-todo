from starlette.middleware import Middleware
from starlette.middleware.cors import CORSMiddleware
from starlette.types import ASGIApp, Receive, Scope, Send


class SecurityHeadersMiddleware:
    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        async def _send(msg):
            if msg.get("type") == "http.response.start":
                add = [
                    (b"x-content-type-options", b"nosniff"),
                    (b"x-frame-options", b"DENY"),
                    (b"referrer-policy", b"no-referrer"),
                    (b"permissions-policy", b"geolocation=(), microphone=(), camera=()"),
                    (b"strict-transport-security", b"max-age=63072000; includeSubDomains; preload"),
                    (b"cross-origin-opener-policy", b"same-origin"),
                    (b"cross-origin-resource-policy", b"same-site"),
                    (b"cross-origin-embedder-policy", b"require-corp"),
                    (
                        b"content-security-policy",
                        b"default-src 'none'; connect-src 'self'; img-src 'self' data:; script-src 'self'; style-src 'self' 'unsafe-inline'",
                    ),
                ]
                base = msg.get("headers", [])
                exists = {k for k, _ in base}
                for k, v in add:
                    if k not in exists:
                        base.append((k, v))
                msg["headers"] = base
            await send(msg)

        await self.app(scope, receive, _send)


def security_middlewares():
    import os

    origins = [o.strip() for o in os.getenv("CORS_ALLOW_ORIGINS", "").split(",") if o.strip()]
    cors = Middleware(
        CORSMiddleware,
        allow_origins=origins if origins else [],
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        allow_credentials=False,
        max_age=600,
    )
    return [Middleware(SecurityHeadersMiddleware), cors]

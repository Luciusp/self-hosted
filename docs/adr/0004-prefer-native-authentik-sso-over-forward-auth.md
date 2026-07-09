# Native Authentik SSO, not proxy forward-auth

Authentication is handled per-service via each service's first-class Authentik integration (OIDC/SAML), configured as part of that service's own setup. We prefer adopting services that have true Authentik integrations and avoid Caddy/proxy-level forward-auth wherever a native option exists.

The goal is genuine end-to-end SSO rather than a proxy gate bolted in front of unauthenticated apps. Forward-auth produces an inconsistent experience (double logins, no per-app identity) and hides identity from the app. However, some services lack any native Authentik integration (e.g. Pi-hole). For these, forward-auth is an accepted fallback — the service's own password is removed so Authentik is the sole gatekeeper, and direct IP access is blocked per ADR 0010 so the forward-auth path cannot be bypassed.

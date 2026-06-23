# Native Authentik SSO, not proxy forward-auth

Authentication is handled per-service via each service's first-class Authentik integration (OIDC/SAML), configured as part of that service's own setup. We do **not** use Caddy/proxy-level forward-auth, and we prefer adopting services that have true Authentik integrations.

The goal is genuine end-to-end SSO rather than a proxy gate bolted in front of unauthenticated apps. Forward-auth produces an inconsistent experience (double logins, no per-app identity) and hides identity from the app. The cost is that services lacking a native Authentik integration are less attractive to adopt — an accepted constraint.

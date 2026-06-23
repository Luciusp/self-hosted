# Komodo GitOps for Compose stack deployment

Docker Compose stacks live in external Git (this repo / GitHub) and are deployed to LXC Domains by Komodo: a core + UI running in the `forge` domain, with periphery agents on all six LXC Domains installed via cloud-init.

We picked a GitOps agent over manual `git pull` + compose and over CI/CD-from-Codeberg. Komodo gives a single pane of glass for `pull && up` across all six hosts with drift visibility, while avoiding the bootstrap dependency that CI-from-Codeberg would create (Codeberg itself lives in `forge`). The core lives in `forge` because Komodo is Git-driven tooling, keeping all Git/source concerns in one domain; `security` stays scoped to auth/VPN only.

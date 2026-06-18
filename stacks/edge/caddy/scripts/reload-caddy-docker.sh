#/bin/bash
# force format caddy config
docker compose exec -w /etc/caddy caddy caddy fmt --overwrite

# gracefully reload caddy config
docker compose exec -w /etc/caddy caddy caddy reload

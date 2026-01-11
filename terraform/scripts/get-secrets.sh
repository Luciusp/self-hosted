#!/bin/sh

set -e

if ! command -v bws >/dev/null 2>&1; then
    echo "Error: bws command not found" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq command not found" >&2
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 <secret-name-1> [secret-name-2] ..." >&2
    exit 1
fi

secrets_json=$(bws secret list --output json)

# Build JSON object with requested secrets
echo "$secrets_json" | jq -n --argjson secrets "$(cat)" --args \
    'reduce $ARGS.positional[] as $name ({};
        . + {($name): ($secrets[] | select(.key == $name) | .value // "")}
    )' -- "$@"

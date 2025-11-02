#!/bin/bash

[[ -z "${NTFY_HOST}" ]] && echo 'Missing NTFY_HOST environment variable'; exit 1; || NTFY_HOST="${NTFY_HOST}"
[[ -z "${NTFY_BEARER_TOKEN}" ]] && echo 'Missing NTFY_BEARER_TOKEN environment variable'; exit 1; || NTFY_BEARER_TOKEN="${NTFY_BEARER_TOKEN}"

ntfy_trace() {
    curl "https://$NTFY_HOST/$1" \
        -H "Authorization: Bearer $NTFY_BEARER_TOKEN" \
        -H "Priority: min" \
        -H "Title: Notice" \
        -d "$2"
}

ntfy_debug() {
    curl "https://$NTFY_HOST/$1" \
        -H "Authorization: Bearer $NTFY_BEARER_TOKEN" \
        -H "Priority: low" \
        -H "Title: Notice" \
        -d "$2"
}

ntfy_notice() {
    curl "https://$NTFY_HOST/$1" \
        -H "Authorization: Bearer $NTFY_BEARER_TOKEN" \
        -H "Priority: default" \
        -H "Title: Notice" \
        -d "$2"
}

ntfy_info() {
    ntfy_notice "$@"
}

ntfy_warning() {
    curl "https://$NTFY_HOST/$1" \
        -H "Authorization: Bearer $NTFY_BEARER_TOKEN" \
        -H "Priority: high" \
        -H "Title: Warning" \
        -H "Tags: warning" \
        -d "$2"
}

ntfy_warn() {          
    ntfy_warning "$@"
}


ntfy_critical() {
    curl "https://$NTFY_HOST/$1" \
        -H "Authorization: Bearer $NTFY_BEARER_TOKEN" \
        -H "Priority: max" \
        -H "Title: Critical" \
        -H "Tags: rotating_light" \
        -d "$2"
}

ntfy_crit() {          
    ntfy_critical "$@"
}


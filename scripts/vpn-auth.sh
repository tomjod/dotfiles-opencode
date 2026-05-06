#!/usr/bin/env bash
# Extract OpenVPN3 web auth URL and open in browser
SERVICE="${1:-openvpn3-white-pc}"
AUTH_URL=$(journalctl --user -u "$SERVICE" --no-pager --since "10 minutes ago" 2>/dev/null | \
    grep -oP 'https://[^ ]*webauth[^ ]*' | tail -1)
if [ -n "$AUTH_URL" ]; then
    echo "Opening: $AUTH_URL"
    xdg-open "$AUTH_URL" 2>/dev/null || sensible-browser "$AUTH_URL" 2>/dev/null || echo "URL: $AUTH_URL"
else
    echo "No pending VPN auth"
fi

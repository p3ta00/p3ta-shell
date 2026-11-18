#!/bin/bash
# Monitor HTTP servers and reverse shell listeners for CTF work
# Designed to be fast (no subprocess forks in awk) — called every 3s by zjstatus

PY_ICON=$''
PHP_ICON=$''

output=""

# HTTP servers: Python and PHP only — pure awk, no subprocess
http_listeners=$(ss -tlnp 2>/dev/null | awk -v py="$PY_ICON" -v php="$PHP_ICON" '
    $1 == "LISTEN" && $4 ~ /:(80|443|8000|8080|8888|9000)$/ {
        split($4, addr, ":");
        port = addr[length(addr)];
        if ($NF ~ /python/) { print port ":" py }
        else if ($NF ~ /php/)   { print port ":" php }
    }
' | sort -u)

# Netcat / shell listeners on common catch ports — pure awk
nc_listeners=$(ss -tlnp 2>/dev/null | awk '
    $1 == "LISTEN" && ($NF ~ /nc|ncat|netcat|penelope|pwncat/) {
        split($4, addr, ":");
        print addr[length(addr)]
    }
' | sort -u)

# Established reverse shells into our listeners
caught_shells=$(ss -tnp 2>/dev/null | awk '
    $1 == "ESTAB" && ($NF ~ /nc|ncat|netcat|penelope|pwncat|python|php/) {
        split($5, remote, ":");
        split(remote[1], oct, ".");
        if (length(oct) == 4)
            print oct[3] "." oct[4] ":sh"
        else
            print remote[1] ":sh"
    }
' | sort -u | head -3)

# Build output string
if [ -n "$http_listeners" ]; then
    count=$(printf '%s\n' "$http_listeners" | wc -l)
    disp=$(printf '%s\n' "$http_listeners" | head -2 | tr '\n' ' ' | sed 's/ $//')
    [ "$count" -gt 2 ] && disp="$disp+$((count-2))"
    output="HTTP:$disp"
fi

if [ -n "$nc_listeners" ]; then
    count=$(printf '%s\n' "$nc_listeners" | wc -l)
    disp=$(printf '%s\n' "$nc_listeners" | head -2 | tr '\n' ',' | sed 's/,$//')
    [ "$count" -gt 2 ] && disp="$disp+$((count-2))"
    [ -n "$output" ] && output="$output | "
    output="${output}LST:$disp"
fi

if [ -n "$caught_shells" ]; then
    disp=$(printf '%s\n' "$caught_shells" | tr '\n' ' ' | sed 's/ $//')
    [ -n "$output" ] && output="$output | "
    output="${output}CAUGHT:$disp"
fi

echo "${output:-idle}"

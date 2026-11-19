#!/bin/bash

declare -a paths=()
declare -a deps_list=()
declare -a codes=()

current_path=""
current_deps=""

# 1. Parse -rule[:dep1:dep2] -subrule[:dep] "bash code"
while (( $# > 0 )); do
    if [[ "$1" == -* ]]; then
        token="${1#-}"
        
        # Split on first ':' if dependencies are present
        if [[ "$token" == *:* ]]; then
            rule_name="${token%%:*}"
            deps="${token#*:}"
            # Convert ':' separators into spaces (e.g., "a:b" -> "a b")
            deps="${deps//:/ }"
            current_deps="${current_deps:+$current_deps }$deps"
        else
            rule_name="$token"
        fi

        current_path="${current_path:+$current_path }$rule_name"
        shift
    else
        if [[ -z "$current_path" ]]; then
            echo "Error: code block '$1' given without a preceding -rule" >&2
            exit 1
        fi
        paths+=("$current_path")
        deps_list+=("$current_deps")
        codes+=("$1")
        current_path=""
        current_deps=""
        shift
    fi
done

if [[ -n "$current_path" ]]; then
    echo "Error: trailing rule '-$current_path' is missing its bash code block" >&2
    exit 1
fi

# Helper to turn a rule path like "build debug" into a valid function name "_rule_build__debug"
to_func_name() {
    local name="$1"
    name="${name// /__}"
    name="${name//-/_}"
    printf '_rule_%s' "$name"
}

# 2. Emit generated script header + dependency runner
cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

declare -A _RAN_RULES=()

_run_rule() {
    local fn="$1"
    # Skip if already executed in this run (prevents diamond-dependency duplicates & infinite loops)
    [[ -n "${_RAN_RULES[$fn]}" ]] && return 0
    _RAN_RULES["$fn"]=1
    "$fn"
}

EOF

# 3. Emit a Bash function for each rule
for i in "${!paths[@]}"; do
    fn_name="$(to_func_name "${paths[$i]}")"
    printf '%s() {\n' "$fn_name"

    # Call each dependency first
    for dep in ${deps_list[$i]}; do
        # Allow dots or slashes in dependency syntax to map to subrules (e.g., "build.clean" -> "build clean")
        dep_path="${dep//./ }"
        dep_fn="$(to_func_name "$dep_path")"
        printf '    _run_rule %s\n' "$dep_fn"
    done

    # Emit the rule's own bash code
    printf '    %s\n' "$(printf '%s' "${codes[$i]}" | envsubst)"
    printf '}\n\n'
done

# 4. Emit the main CLI dispatcher
cat <<'EOF'
case "$*" in
EOF

for i in "${!paths[@]}"; do
    fn_name="$(to_func_name "${paths[$i]}")"
    printf '    %q)\n' "${paths[$i]}"
    printf '        _run_rule %s\n' "$fn_name"
    printf '        ;;\n'
done

cat <<'EOF'
    *)
        echo "Unknown rule: $*" >&2
        exit 1
        ;;
esac
EOF

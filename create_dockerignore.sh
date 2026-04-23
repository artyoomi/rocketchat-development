#!/bin/sh

# Extract COPY sources from Dockerfile and create .dockerignore
# that only allows those files (ignores everything else)
# Usage: ./create-dockerignore.sh [Dockerfile]

DOCKERFILE="${1:-Dockerfile}"
DOCKERIGNORE="${2:-.dockerignore}"
TEMP_FILE="/tmp/dockerignore_temp_$$"

if [ ! -f "$DOCKERFILE" ]; then
    echo "Error: $DOCKERFILE not found" >&2
    exit 1
fi

echo "Generating $DOCKERIGNORE..."

# Create header comment
cat > "$TEMP_FILE" << EOF
# Auto-generated .dockerignore
# This file ignores everything except files/directories used in COPY commands
# Generated from: DOCKERFILE_PLACEHOLDER
# DO NOT EDIT MANUALLY - regenerate with: ./create_dockerignore.sh

# Ignore everything first
*

EOF

# Replace placeholder
sed -i "s|DOCKERFILE_PLACEHOLDER|$DOCKERFILE|" "$TEMP_FILE"

# Extract all source files/directories from COPY commands
grep -E '^COPY\s+' "$DOCKERFILE" | while read -r line; do
    # Remove COPY keyword
    line=$(echo "$line" | sed 's|^[Cc][Oo][Pp][Yy]\s\+||')

    # Remove flags (--chown, --from, etc.)
    while echo "$line" | grep -q '^--'; do
        if echo "$line" | grep -q '^--[a-z-]*='; then
            # Case: --flag=value
            line=$(echo "$line" | sed 's/^--[a-z-]*=[^[:space:]]*\s\+//')
        else
            # Case: --flag value
            line=$(echo "$line" | sed 's/^--[a-z-]*\s\+[^[:space:]]*\s\+//')
        fi
    done

    # Remove destination (last field)
    sources=$(echo "$line" | awk '{$NF=""; print $0}' | sed 's/[[:space:]]*$//')

    # Split multiple sources
    echo "$sources" | tr ' ' '\n' | while read -r src; do
        if [ -n "$src" ]; then
            # Remove trailing slash if present (for directories)
            src_clean=$(echo "$src" | sed 's:/*$::')

            # Add to .dockerignore with ! prefix
            echo "!$src_clean" | sort -u >> "$TEMP_FILE"
            echo -e "\tAdded: $src_clean"

            # If it's a directory pattern, also allow contents
            if [ -d "$src_clean" ] 2>/dev/null || echo "$src_clean" | grep -q '/$'; then
                echo "!$src_clean/**" >> "$TEMP_FILE"
            fi
        fi
    done
done

# Remove duplicate entries
cat "$TEMP_FILE" > "$DOCKERIGNORE"
rm "$TEMP_FILE"

echo "Created $DOCKERIGNORE with $(grep -c '^!' "$DOCKERIGNORE") allowed files/directories"

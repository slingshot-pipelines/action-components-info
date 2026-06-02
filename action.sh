#!/bin/bash -eu

if ! [[ -d ".components" ]]; then
    >&2 echo "No .components directory found"
    exit 1
fi

PROJECT_JSON=$(cat .components/info.yml | yq -o=json -I0 '.')

INFO_FILES=$(find .components \
    -name 'info.yml' \
    -type f \
    -mindepth 2 \
    -maxdepth 2 \
    | sort -u)

ALL_COMPONENTS='{}'


# Add a .components component
ALL_COMPONENTS=$(echo "$ALL_COMPONENTS" \
    | jq -rc \
        '. | .[".components"] = { component: ".components", type: "components", path: ".components" }')

# Add a .github component, if appropriate
if [[ -d ".github/actions" || -d ".github/workflows" ]]; then
    ALL_COMPONENTS=$(echo "$ALL_COMPONENTS" \
        | jq -rc \
            '. | .[".github"] = { component: ".github", type: "github-actions" }')
fi

while IFS='' read -r INFO_FILE && [[ -n "$INFO_FILE" ]]; do
    COMPONENT_JSON=$(cat "$INFO_FILE" | yq -o=json -I0 '.')

    ALL_COMPONENTS=$(echo "$ALL_COMPONENTS" \
        | jq -rc \
            --argjson project "$PROJECT_JSON" \
            --argjson component "$COMPONENT_JSON" \
            '. | .[$component.component] = ($component + $project | .fullname |= "\($project.project)/\($component.component)")')
done <<< "$INFO_FILES"

printf '%s' "$ALL_COMPONENTS"

# lib/frontmatter.sh — YAML/TOML frontmatter builders and line counter
# Sourced by writer.sh. Do not execute directly.

build_yaml_frontmatter() {
    local title="$1"
    local slug="$2"
    local date="$3"
    local tags="$4"
    local description="$5"
    local draft="$6"

    local fm="---\n"
    fm+="title: \"${title}\"\n"
    fm+="date: ${date}\n"
    fm+="slug: \"${slug}\"\n"

    if [[ -n "$tags" ]]; then
        fm+="tags:\n"
        IFS=',' read -ra tag_array <<< "$tags"
        for tag in "${tag_array[@]}"; do
            tag="${tag#"${tag%%[![:space:]]*}"}"
            tag="${tag%"${tag##*[![:space:]]}"}"
            if [[ -z "$tag" ]]; then continue; fi
            fm+="  - ${tag}\n"
        done
    fi

    if [[ -n "$description" ]]; then
        fm+="description: \"${description}\"\n"
    fi

    fm+="draft: ${draft}\n"
    fm+="---\n"

    printf "%b" "$fm"
}

build_toml_frontmatter() {
    local title="$1"
    local slug="$2"
    local date="$3"
    local tags="$4"
    local description="$5"
    local draft="$6"

    local fm="+++\n"
    fm+="title = \"${title}\"\n"
    fm+="date = ${date}\n"
    fm+="slug = \"${slug}\"\n"

    if [[ -n "$tags" ]]; then
        local tag_list=""
        IFS=',' read -ra tag_array <<< "$tags"
        local first=true
        for tag in "${tag_array[@]}"; do
            tag="${tag#"${tag%%[![:space:]]*}"}"
            tag="${tag%"${tag##*[![:space:]]}"}"
            if [[ -z "$tag" ]]; then continue; fi
            if [[ "$first" == "true" ]]; then
                tag_list="\"${tag}\""
                first=false
            else
                tag_list+=", \"${tag}\""
            fi
        done
        if [[ -n "$tag_list" ]]; then fm+="tags = [${tag_list}]\n"; fi
    fi

    if [[ -n "$description" ]]; then
        fm+="description = \"${description}\"\n"
    fi

    fm+="draft = ${draft}\n"
    fm+="+++\n"

    printf "%b" "$fm"
}

count_frontmatter_lines() {
    local format="$1"
    local title="$2"
    local tags="$3"
    local description="$4"

    # Delimiter lines: 2 (open + close)
    local count=2
    # Fixed fields: title, date, slug, draft = 4
    count=$((count + 4))

    if [[ -n "$tags" ]]; then
        if [[ "$format" == "yaml" ]]; then
            count=$((count + 1)) # "tags:" line
            IFS=',' read -ra tag_array <<< "$tags"
            for tag in "${tag_array[@]}"; do
                tag="${tag#"${tag%%[![:space:]]*}"}"
                tag="${tag%"${tag##*[![:space:]]}"}"
                if [[ -z "$tag" ]]; then continue; fi
                count=$((count + 1))
            done
        else
            count=$((count + 1)) # single tags = [...] line
        fi
    fi

    if [[ -n "$description" ]]; then count=$((count + 1)); fi

    echo "$count"
}

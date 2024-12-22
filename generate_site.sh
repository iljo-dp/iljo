set -e

BASE_DIR="$(dirname "$(realpath "$0")")"

TEMPLATE_FILE="$BASE_DIR/template.html"

OUTPUT_BASE_DIR="$BASE_DIR/notes"

MARKDOWN_DIR="$OUTPUT_BASE_DIR/markdown"

TMP_CONTENT="$(mktemp)"

urlencode() {
    local string="$1"
    local length="${#string}"
    local encoded=""
    for (( i = 0; i < length; i++ )); do
        local c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            *) printf -v hex '%%%02X' "'$c"
               encoded+="$hex" ;;
        esac
    done
    echo "$encoded"
}

if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is not installed. Please install pandoc to proceed."
    exit 1
fi

find "$MARKDOWN_DIR" -name '*.md' | while read -r mdfile; do
    TITLE=$(grep '^Title:' "$mdfile" | sed 's/^Title:[ \t]*//')
    CATEGORY=$(grep '^Category:' "$mdfile" | sed 's/^Category:[ \t]*//')
    DATE=$(grep '^Date:' "$mdfile" | sed 's/^Date:[ \t]*//')

    if [[ -z "$TITLE" || -z "$CATEGORY" || -z "$DATE" ]]; then
        echo "Skipping '$mdfile' due to missing metadata."
        continue
    fi

    FILENAME=$(basename "$mdfile" .md)

    CATEGORY_DIR="$OUTPUT_BASE_DIR/$CATEGORY"
    mkdir -p "$CATEGORY_DIR"

    OUTPUT_FILE="$CATEGORY_DIR/$FILENAME.html"

    if [[ -f "$OUTPUT_FILE" ]]; then
        echo "Skipping '$OUTPUT_FILE' as it already exists."
        continue
    fi

    CONTENT=$(sed '1,/^$/d' "$mdfile")

    echo "$CONTENT" | pandoc -f markdown -t html -o "$TMP_CONTENT"

    ARTICLE_CONTENT=$(cat "$TMP_CONTENT")

    CATEGORY_ENCODED=$(urlencode "$CATEGORY")
    FILENAME_ENCODED=$(urlencode "$FILENAME.html")
    OG_URL="https://iljo.dev/notes/$CATEGORY_ENCODED/$FILENAME_ENCODED"

    export TITLE
    export DATE
    export CONTENT
    export CATEGORY_ENCODED
    export FILENAME_ENCODED
    export OG_URL

    OUTPUT_CONTENT=$(envsubst < "$TEMPLATE_FILE")

    echo "$OUTPUT_CONTENT" > "$OUTPUT_FILE"

    echo "Generated '$OUTPUT_FILE'"
done

rm "$TMP_CONTENT"

echo "Article generation completed successfully."

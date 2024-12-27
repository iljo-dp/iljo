#!/usr/bin/env bash
set -e

BASE_DIR="$(dirname "$(realpath "$0")")"

TEMPLATE_FILE="$BASE_DIR/template.html"
OUTPUT_BASE_DIR="$BASE_DIR/notes"
MARKDOWN_DIR="$OUTPUT_BASE_DIR/markdown"
TMP_CONTENT="$(mktemp)"

INDEX_HTML="$BASE_DIR/index.html"
NOTES_HTML="$BASE_DIR/notes.html"

# ----------------------------------------------------------------------
# Simple URL-encoding helper
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# Helper to insert a new <tr> for an article into both index.html and notes.html
# using awk rather than sed to avoid escaping issues.
# ----------------------------------------------------------------------
add_article_to_index_and_notes() {
    local date="$1"
    local title="$2"
    local category="$3"
    local filename_no_ext="$4"

    # For the link inside HTML:
    local article_link="notes/$category/$filename_no_ext.html"

    # -------------------------------
    # 1. Insert into index.html
    # -------------------------------
    if grep -q "$article_link" "$INDEX_HTML"; then
        echo "Article already found in index.html. Skipping insertion."
    else
        # Build the row for index.html
        # Notice we use cat <<EOF ... EOF to create a multi-line string
        local index_row
        index_row="$(cat <<EOF
              <tr>
                <td>
                  <time datetime="$date">$date</time>
                </td>
                <td>
                  <a href="$article_link" title="$title">$title</a>
                </td>
                <td class="hide-phone">
                  <a class="btn btn-sm bg-dark-green white hover-white hover-bg-black measure-6"
                    href="$article_link"
                    title="Read Article - $title">Read
                    →</a><br />
                </td>
              </tr>
EOF
)"

        # Use awk to inject above </tbody>:
        awk -v row="$index_row" '
          /<\/tbody>/ {
            print row
          }
          { print }
        ' "$INDEX_HTML" > "$INDEX_HTML.tmp"

        mv "$INDEX_HTML.tmp" "$INDEX_HTML"
        echo "Appended new article to index.html."
    fi

    # -------------------------------
    # 2. Insert into notes.html
    # -------------------------------
    if grep -q "$article_link" "$NOTES_HTML"; then
        echo "Article already found in notes.html. Skipping insertion."
    else
        # Build the row for notes.html
        local notes_row
        notes_row="$(cat <<EOF
              <tr>
                <td>
                  <time datetime="$date">$date</time>
                </td>
                <td class="pv1 pr4 dtc">
                  <a href="$article_link" title="$title">$title
                  </a>
                </td>
              </tr>
EOF
)"

        awk -v row="$notes_row" '
          /<\/tbody>/ {
            print row
          }
          { print }
        ' "$NOTES_HTML" > "$NOTES_HTML.tmp"

        mv "$NOTES_HTML.tmp" "$NOTES_HTML"
        echo "Appended new article to notes.html."
    fi
}

# ----------------------------------------------------------------------
# Check for Pandoc
# ----------------------------------------------------------------------
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is not installed. Please install pandoc to proceed."
    exit 1
fi

# ----------------------------------------------------------------------
# Main loop: discover all .md, parse metadata, generate HTML if needed
# ----------------------------------------------------------------------
find "$MARKDOWN_DIR" -name '*.md' | while read -r mdfile; do
    TITLE=$(grep '^Title:' "$mdfile"    | sed 's/^Title:[ \t]*//')
    CATEGORY=$(grep '^Category:' "$mdfile" | sed 's/^Category:[ \t]*//')
    DATE=$(grep '^Date:' "$mdfile"      | sed 's/^Date:[ \t]*//')

    if [[ -z "$TITLE" || -z "$CATEGORY" || -z "$DATE" ]]; then
        echo "Skipping '$mdfile' due to missing metadata (Title, Category, or Date)."
        continue
    fi

    FILENAME=$(basename "$mdfile" .md)
    CATEGORY_DIR="$OUTPUT_BASE_DIR/$CATEGORY"
    mkdir -p "$CATEGORY_DIR"

    OUTPUT_FILE="$CATEGORY_DIR/$FILENAME.html"

    # If the file already exists, skip generation
    if [[ -f "$OUTPUT_FILE" ]]; then
        echo "Skipping '$OUTPUT_FILE' as it already exists."
        continue
    fi

    # Extract everything after the first blank line as the content
    CONTENT=$(sed '1,/^$/d' "$mdfile")

    # Convert markdown to HTML via pandoc
    echo "$CONTENT" | pandoc -f markdown -t html -o "$TMP_CONTENT"
    ARTICLE_CONTENT=$(cat "$TMP_CONTENT")

    # Build OG url
    CATEGORY_ENCODED=$(urlencode "$CATEGORY")
    FILENAME_ENCODED=$(urlencode "$FILENAME.html")
    OG_URL="https://iljo.dev/notes/$CATEGORY_ENCODED/$FILENAME_ENCODED"

    export TITLE DATE CONTENT ARTICLE_CONTENT CATEGORY_ENCODED FILENAME_ENCODED OG_URL

    # Insert your article content into the template
    OUTPUT_CONTENT=$(envsubst < "$TEMPLATE_FILE")
    echo "$OUTPUT_CONTENT" > "$OUTPUT_FILE"

    echo "Generated '$OUTPUT_FILE'."

    # Now that the article is generated, we append a row in index.html & notes.html
    add_article_to_index_and_notes "$DATE" "$TITLE" "$CATEGORY" "$FILENAME"
done

# ----------------------------------------------------------------------
# Clean up
# ----------------------------------------------------------------------
rm -f "$TMP_CONTENT"

echo "Article generation completed successfully."


#!/usr/bin/env bash

SITE_URL="https://blog.pertsovsky.com"
POST_DIR="posts"
ASSETS_DIR="assets"
OUTPUT_DIR="docs"
LAYOUT_HTML=$(<layout.html)
INDEX_HTML=$(<index.html)

rm -r $OUTPUT_DIR
mkdir -p $OUTPUT_DIR
cp -r $ASSETS_DIR "$OUTPUT_DIR/"

get_front_matter_json() {
	local post_path=$1
	awk '/^---$/ {flag=!flag; next} flag' "$post_path" | yq
}

get_content_without_front_matter() {
	local post_path=$1
	awk '/^---$/ {flag=!flag; next} !flag' "$post_path" | pandoc -f markdown -t html
}

compile_post() {
	local post_path=$1
	local title=$2
	local date=$3
	local file_name_without_format=$4
	local wrapped_title="<h1>$title</h1>"
	local content_pandoc_html
	content_pandoc_html=$(get_content_without_front_matter "$post_path")

	echo "$LAYOUT_HTML" | awk -v date="$date" \
		-v title="$wrapped_title" \
		-v content="$content_pandoc_html" '
  {
    gsub("{{ date }}", date)
    gsub("{{ title }}", title)
    gsub("{{ content }}", content)
    print
  }' >"$OUTPUT_DIR/$file_name_without_format.html"
}

compile_index_and_rss() {
	local posts=""
	local rss_items=""

	local rss_layout
	rss_layout=$(<rss_layout.xml)

	for post_path in "$POST_DIR"/*.md; do
		file_name=$(basename "$post_path")
		file_name_without_format="${file_name%.*}"

		front_matter_json=$(get_front_matter_json "$post_path")
		title=$(echo "$front_matter_json" | jq -r '.title')
		date=$(echo "$front_matter_json" | jq -r '.date')

		posts+="<li><a href=\"$file_name_without_format.html\">$date - $title</a></li>"

		content_pandoc_html=$(get_content_without_front_matter "$post_path")

		rss_items+="
      <item>
        <title>$title</title>
        <link>$SITE_URL/$file_name_without_format.html</link>
        <description>
          <![CDATA[$content_pandoc_html]]>
        </description>
        <pubDate>$date</pubDate>
      </item>"
	done

	local rss_content
	rss_content=$(echo "$rss_layout" | awk -v items="$rss_items" '{gsub("{{ items }}", items); print}')

	echo "$INDEX_HTML" | awk -v posts="$posts" '
  {
    gsub("{{ posts }}", posts)
    print
  }' >"$OUTPUT_DIR/index.html"

	echo "$rss_content" >"$OUTPUT_DIR/rss.xml"
}

for post_path in "$POST_DIR"/*.md; do
	file_name=$(basename "$post_path")
	file_name_without_format="${file_name%.*}"
	front_matter_json=$(get_front_matter_json "$post_path")

	date=$(echo "$front_matter_json" | jq -r '.date')
	title=$(echo "$front_matter_json" | jq -r '.title')

	compile_post "$post_path" "$title" "$date" "$file_name_without_format"
done

compile_index_and_rss

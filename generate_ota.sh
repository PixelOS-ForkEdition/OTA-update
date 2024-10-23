#!/bin/bash

# Path to the maintainer info file
maintainer_info_file="./OTA/maintainer_info.txt"

# Prompt user for device codename
read -p "Enter device codename (e.g. PL2, miatoll): " codename

# Prompt user for release tag
read -p "Enter release tag (e.g. mm-yyyy): " release_tag

# Construct the expected OTA package path
ota_package_dir="out/target/product/${codename}"
file_path=$(ls ${ota_package_dir}/PixelOS_*_${codename}-*.zip 2>/dev/null)

# Check if the OTA package exists
if [[ -z "$file_path" ]]; then
  echo "OTA package file not found in ${ota_package_dir}."
  echo "Ensure the file follows the pattern: PixelOS_*_${codename}-*.zip"
  exit 1
else
  echo "Found OTA package: $file_path"
fi

# Extract filename from the path
filename=$(basename "$file_path")

# Construct the download URL
url="https://github.com/PixelOS-ForkEdition/OTA-update/releases/download/u_${codename}_${release_tag}/${filename}"

# Default values
output_dir="./OTA/devices"
version="fourteen"  # Default version value
datetime=$(grep -oP '^ro.build.date.utc=\K\d+' "${ota_package_dir}/system/build.prop" 2>/dev/null || echo "UNKNOWN")

# Generate file hash using sha256sum
id=$(sha256sum "$file_path" | awk '{ print $1 }')

# Get the file size
size=$(stat -c%s "$file_path")

# Define URLs
ota_datetime="TIMESTAMP_PLACEHOLDER"
github_releases_url="$url"
website_url="https://pixelos.net/"
news_url="https://blog.pixelos.net/"

# Extract maintainer info using awk, trimming spaces and newlines
maintainer_name=$(awk -F'=' -v codename="$codename" '$0 ~ "\\["codename"\\]" {flag=1; next} /^\[/ {flag=0} flag && $1=="maintainer_name" {gsub(/"/, "", $2); print $2}' "$maintainer_info_file" | xargs)
github_username=$(awk -F'=' -v codename="$codename" '$0 ~ "\\["codename"\\]" {flag=1; next} /^\[/ {flag=0} flag && $1=="github_username" {gsub(/"/, "", $2); print $2}' "$maintainer_info_file" | xargs)
main_maintainer=$(awk -F'=' -v codename="$codename" '$0 ~ "\\["codename"\\]" {flag=1; next} /^\[/ {flag=0} flag && $1=="main_maintainer" {gsub(/"/, "", $2); print $2}' "$maintainer_info_file" | xargs)
donate_url=$(awk -F'=' -v codename="$codename" '$0 ~ "\\["codename"\\]" {flag=1; next} /^\[/ {flag=0} flag && $1=="donate_url" {gsub(/"/, "", $2); print $2}' "$maintainer_info_file" | xargs)
forum_url=$(awk -F'=' -v codename="$codename" '$0 ~ "\\["codename"\\]" {flag=1; next} /^\[/ {flag=0} flag && $1=="forum_url" {gsub(/"/, "", $2); print $2}' "$maintainer_info_file" | xargs)

# Verify if maintainer info was properly fetched
if [[ -z "$maintainer_name" || -z "$github_username" || -z "$main_maintainer" || -z "$donate_url" || -z "$forum_url" ]]; then
  echo "Maintainer info for '$codename' not found or incomplete in $maintainer_info_file."
  exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Define the output JSON file path
output_file="${output_dir}/${codename}.json"

# Create the JSON content
json=$(cat <<EOF
{
  "error": false,
  "version": "$version",
  "filename": "$filename",
  "datetime": $datetime,
  "ota_datetime": "$ota_datetime",
  "size": $size,
  "url": "$url",
  "github_releases_url": "$github_releases_url",
  "filehash": "$id",
  "id": "$id",
  "maintainers": [
    {
      "main_maintainer": "$main_maintainer",
      "github_username": "$github_username",
      "name": "$maintainer_name"
    }
  ],
  "donate_url": "$donate_url",
  "website_url": "$website_url",
  "news_url": "$news_url",
  "forum_url": "$forum_url"
}
EOF
)

# Save the JSON, prettify it if jq is installed
if command -v jq &> /dev/null; then
  echo "$json" | jq '.' > "$output_file"
else
  echo "$json" > "$output_file"
fi

# Confirmation message
echo "JSON has been saved to $output_file"

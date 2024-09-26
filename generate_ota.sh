#!/bin/bash

# Prompt user for device codename
read -p "Enter device codename (e.g. PL2, miatoll): " codename

# Prompt user for release tag
read -p "Enter release tag (e.g. mm-yyyy): " release_tag

# Read maintainer information, donate URL, forum URL, GitHub username, and main maintainer status from the text file
info_file="./maintainer_info.txt"

# Function to extract data for a given device codename
get_value_from_info_file() {
    local key=$1
    awk -v codename="[$codename]" -v key="$key" '
    $0 == codename { in_section=1; next }
    in_section && $1 == key { print substr($0, index($0, "=")+1); exit }
    $0 ~ /^\[/ { in_section=0 }
    ' "$info_file" | sed 's/^"\(.*\)"$/\1/'  # This removes quotes if they exist
}

if [[ -f "$info_file" ]]; then
  maintainer_name=$(get_value_from_info_file "maintainer_name")
  github_username=$(get_value_from_info_file "github_username")
  main_maintainer=$(get_value_from_info_file "main_maintainer")
  donate_url=$(get_value_from_info_file "donate_url")
  forum_url=$(get_value_from_info_file "forum_url")

  # Check if the values were found
  if [[ -z "$maintainer_name" || -z "$github_username" || -z "$main_maintainer" || -z "$donate_url" || -z "$forum_url" ]]; then
    echo "Maintainer info for '$codename' not found or incomplete in $info_file"
    exit 1
  fi
else
  echo "Maintainer info file not found: $info_file"
  exit 1
fi

# Construct URL using the release tag and filename
file_path=$(ls out/target/product/${codename}/PixelOS_*_${codename}.zip 2>/dev/null)
filename=$(basename "$file_path")
url="https://github.com/PixelOS-ForkEdition/OTA-update/releases/download/u_${codename}_${release_tag}/${filename}"

# Default values
output_dir="./OTA/devices"
version="fourteen"  # Set version default to fourteen
datetime=$(grep -oP '^ro.build.date.utc=\K\d+' "out/target/product/${codename}/system/build.prop")

# Check if the OTA package file exists
if [[ -z "$file_path" ]]; then
  echo "OTA package file not found in the specified directory."
  exit 1
fi

# Generate ID using sha256sum
id=$(sha256sum "$file_path" | awk '{ print $1 }')

# Get the file size
size=$(stat -c%s "$file_path")

# Add placeholder for ota_datetime and set default URLs
ota_datetime="TIMESTAMP_PLACEHOLDER"
github_releases_url="$url"
website_url="https://pixelos.net/"
news_url="https://blog.pixelos.net/"

# Create JSON
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
      "main_maintainer": $main_maintainer,
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

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Define the output file path
output_file="${output_dir}/${codename}.json"

# Write JSON to the specified file
echo "$json" > "$output_file"

# Confirmation message
echo "JSON has been saved to $output_file"

#!/bin/bash
# vim: set sw=2 :

set -euo pipefail

die() {
  echo $* >&2
  exit 1
}

parse_args() {
  if [[ $# -ne 1 ]]; then
    die 'Usage: split_pdf.sh <PDF file>'
  fi

  # Set global variables
  pdf_file=${1:?}
}

split_pages() {
  local IFS=''
  local line
  local cur_title
  local cur_page

  while true; do
    read -r line
    local title=$(grep -Po '^BookmarkTitle: \K.*$' <<< "$line")
    if [[ -z "$title" ]]; then
      continue
    fi

    read -r line
    local level=$(grep -Po '^BookmarkLevel: \K[0-9]+$' <<< "$line")
    if [[ -z "$level" ]]; then
      die 'ERROR: "BookmarkLevel" not found'
    fi

    read -r line
    local page=$(grep -Po '^BookmarkPageNumber: \K[0-9]+$' <<< "$line")
    if [[ -z "$page" ]]; then
      die 'ERROR: "BookmarkPageNumber" not found'
    fi

    if [[ $level -eq 1 ]]; then
      cur_title="$title"
      cur_page="$page"
    elif [[ $level -eq 2 ]]; then
      page_offset=$(( $page - $cur_page ))
      output_file="${cur_title}_${page_offset}.pdf"
      pdftk $pdf_file cat $page output ~$output_file
      pdfcrop ~$output_file $output_file
      rm -f ~$output_file
    fi
  done
}

main() {
  parse_args $*
  pdftk $pdf_file dump_data output | split_pages
}

main $*

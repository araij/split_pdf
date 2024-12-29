#!/bin/bash
# vim: set sw=2 :

#
# Copyright (c) 2024 ARAI Junya.
# Released under the MIT License <http://opensource.org/licenses/MIT>.
#

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

#
# Prints level-1 sections by parsing PDF metadata.
# The output looks as follows:
# ```
# <Beginning Page> <Section Title>
# <Beginning Page> <Section Title>
# ...
# <Beginning Page> <Section Title>
# <Last Page + 1>
# ```
#
toplevel_sections() {
  local IFS=''
  local line

  while read -r line; do
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
      echo "${page} ${title}"
    fi
  done

  echo $(( ${page} + 1 ))
}


split_pages() {
  local line
  local page
  local title
  local page_end

  tac | while read -r page title; do
    if [[ -n "$title" ]]; then
      local output_file="${title}.pdf"
      pdftk $pdf_file cat $page-$page_end output ~$output_file
      pdfcrop ~$output_file $output_file
      rm -f ~$output_file
    fi

    page_end=$(( $page - 1 ))
  done
}

main() {
  parse_args $*
  pdftk $pdf_file dump_data output | toplevel_sections | split_pages
}

main $*

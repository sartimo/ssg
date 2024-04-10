#!/usr/bin/env bash
set -eo > /dev/null

input_directory=in
output_directory=out

generate_blog_index_md () {
  blog_index_md=$input_directory/blog.md
  echo "---" > $blog_index_md
  echo "title: Technical Blog - Posts" >> $blog_index_md
  echo "---" >> $blog_index_md
  for post in $(find $input_directory/posts/ -name "*.md" | sort -r)
  do
    date=$(date -d $(grep -m 1 "date: " $post | cut -d " " -f 2) +%F)
    title=$(grep -m 1 "title: " $post | cut -d " " -f 2-)
    link=$(basename $post | sed -E "s/^[0-9-]+//" | sed -E "s/md$/html/")
    echo "- [$date - $title]($link)" >> $blog_index_md
  done
}

generate_pages_html () {
  for input_page in $(find $input_directory -name "*.md")
  do
    output_page=${output_directory}/$(basename $input_page | sed -E "s/^[0-9-]+//" | sed -E "s/md$/html/")
    pandoc $input_page -B template/header.html -A template/footer.html --template template/template.html -o $output_page -c res/styles.css
    sed -i "s/…/.../g" $output_page
  done
}

main () {
  mkdir -p $output_directory
  cp -r res $output_directory/
  generate_blog_index_md
  generate_pages_html
}

main

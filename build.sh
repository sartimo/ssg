#!/usr/bin/env bash
# required: GNU CoreUtils, Make, Pandoc

set -eo > /dev/null

# [WORKING] variable assignment
input_directory=in
input_directory_pages=$input_directory/pages
input_directory_posts=$input_directory/posts
output_directory=out

# [WORKING] generate out/index.html from in/index.md
generate_index_page_html () {
    output_page=$output_directory/index.html
    pandoc $input_directory/index.md -B template/header.html --template template/index.html -o $output_page -c res/styles.css
    sed -i "s/…/.../g" $output_page
}

# [WORKING] generate in/articles.md from files at in/posts/*.md
generate_articles_list_md () {
  blog_index_md=$input_directory/pages/articles.md
  echo "---" > $blog_index_md
  echo "title: Articles" >> $blog_index_md
  echo "---" >> $blog_index_md
  for post in $(find $input_directory/posts/ -name "*.md" | sort -r)
  do
    date=$(date -d $(grep -m 1 "date: " $post | cut -d " " -f 2) +%F)
    title=$(grep -m 1 "title: " $post | cut -d " " -f 2-)
    link=$(basename $post | sed -E "s/^[0-9-]+//" | sed -E "s/md$/html/")
    description=$(grep -m 1 "description: " $post | cut -d " " -f 2-)

    echo "- [$title]($link) <em>$date</em><br/>$description<br/>" >> $blog_index_md
  done
}

# [WORKING] generate out/articles.html from in/articles.md
generate_articles_list_html () {
    output_page=$output_directory/articles.html
    pandoc $input_directory/pages/articles.md --template template/articles.html -o $output_page -c res/styles.css
    sed -i "s/…/.../g" $output_page
    rm $input_directory/pages/articles.md
}

# [WORKING] generate out/*.html from in/pages/*.md
generate_pages_html () {
  for input_page in $(find $input_directory_pages -name "*.md")
  do
    output_page=${output_directory}/$(basename $input_page | sed -E "s/^[0-9-]+//" | sed -E "s/md$/html/")
    pandoc $input_page --template template/articles.html -o $output_page -c res/styles.css
    sed -i "s/…/.../g" $output_page
  done
}


# [WORKING] generate out/*.html from in/posts/*.md
generate_posts_html () {
  for input_page in $(find $input_directory_posts -name "*.md")
  do
    output_page=${output_directory}/$(basename $input_page | sed -E "s/^[0-9-]+//" | sed -E "s/md$/html/")
    pandoc $input_page --template template/post.html -o $output_page -c res/styles.css
    sed -i "s/…/.../g" $output_page
  done
}

# [WORKING] main routine
main () {
  mkdir -p $output_directory
  cp -r res $output_directory/
  generate_index_page_html
  generate_articles_list_md
  generate_articles_list_html
  generate_pages_html
  generate_posts_html
}

main
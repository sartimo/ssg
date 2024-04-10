# maze88.dev Static site generator

## Input preparation
1. All content should be written in markdown and put in the `in/` directory.

   > Note: Do *not* create an `in/blog.md` file, since the build will overwrite it when generating the blog index.

2. Blog posts should be placed in the `in/posts/` directory, with filenames that are arranged chronologically by prefix (using numbers and dashes only), such as:
   ```
   00-writing-markdown.md
   01-generating-html.md
   ```
   or
   ```
   2022-01-11-writing-markdown.md
   2022-02-22-generating-html.md
   ```

3.  Each post should contain the following YAML in its frontmatter:
    ```yaml
    ---
    title: Generating HTML with Pandoc
    date: 11/03/2022
    author: Michael Zeevi  # optional
    keywords:  # optional
    - markdown
    - html
    ---
    ```

4. Additional resources and media (CSS, images, PGP public key, etc.) can be put in the `res/` directory, which will be copied to `out/res/` during build.

## Usage
### Local development and testing
1. Build by running `make` (which wraps the `./build.sh` script) - this will clean and then produce the output in the directory `out`.

2. One can test by opening the output locally in their web browser.

### Publishing (deploying)
1. Run `make publish` - this will first _build_ and _copy_ the output to the `../pages/` directory (repository), and then **automatically** _commit_ and _push_ (!) to the remote [pages](https://codeberg.org/maze/pages) repository (thus publishing it).

2. One can test by going to the website with their browser.

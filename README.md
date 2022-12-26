## Install

1. First install ruby via brew (`brew install ruby`). Then make sure the following is in your `.zshrc`:
   ```
   export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.1.0/bin:$PATH"
   ```
2. Install jekyll and bundler: `gem install jekyll bundler`
3. Install everything for this project: `bundler install`

## Usage

1. Run the server: `make serve`
2. Lint: `make lint`

## Documentation

* [Jekyll](https://jekyllrb.com/docs/)
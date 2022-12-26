# Just file documentation: https://github.com/casey/just

_default:
    just -l

# Run the Jekyll server with livereload
@serve:
    docker-compose up

# Do lint checking
@lint:
    docker-compose run --rm jekyll bundle exec rake test

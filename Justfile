# Just file documentation: https://github.com/casey/just

@_default:
    just -l

# Do lint checking
@lint:
    docker compose run --rm jekyll bundle exec rake test

# Start the Jekyll server with livereload
@start:
    docker compose up

# Stop the Jekyll server with livereload
@stop:
    docker compose down

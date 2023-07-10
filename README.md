# JRuby Build Scripts

A set of scripts used to build JRuby packages for Heroku

## Building on Github Actions

See https://github.com/heroku/docker-heroku-ruby-builder#building-with-github-actions for instructions

## Building Locally

Make sure you've generated a docker image:

```
bundle exec rake "generate_image[heroku-22]"
```

Then run the following:

```
bundle exec rake "new[9.3.0.0,heroku-22]" &&
bash rubies/heroku-22/jruby-9.3.0.0.sh &&
bundle exec rake "upload[9.3.0.0,heroku-22]" &&
echo "Done building jruby 9.3.0.0 for heroku-22"
```

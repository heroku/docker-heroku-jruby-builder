# JRuby Build Scripts

A set of scripts used to build JRuby packages for Heroku

## Building on Github Actions

See https://github.com/heroku/docker-heroku-ruby-builder#building-with-github-actions for instructions

## Building Locally

Make sure you've generated a docker image:

```
bin/activate_docker heroku-24
```

Then run the following:

```
bin/build_jruby heroku-24 9.4.7.0
```

This will generate tar files in the `builds` folder. You can exercise them by running:

```
bin/print_summary heroku-24 9.4.7.0
```

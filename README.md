# JRuby Build Scripts

A set of scripts used to build JRuby packages for Heroku

## Building on CircleCI

In order to build, the rubies script must exist and be committed to main.

```
$ bundle exec rake new[9.2.8.0,heroku-18]
$ git add rubies/
$ git commit -m "jruby 9.2.8.0"
$ git push origin master
```

Pass the JRuby version to the build script:

```
$ bash circleci-build.sh "9.2.8.0"
```

This assumes you have a `CIRCLECI_TOKEN` environment variable that contains a GPG encrypted token. You can create this like:

```
$ export CIRCLECI_TOKEN="$(echo "token" | gpg --encrypt --armor)"
```

You can replace "9.2.8.0" with any JRuby version.

### Environment Variables

These enivronment variables are used by the CircleCI project:

* JRUBY_VERSION
* PRODUCTION_BUCKET_NAME
* PRODUCTION_AWS_ACCESS_KEY_ID
* PRODUCTION_AWS_SECRET_ACCESS_KEY
* HEROKU_API_KEY

## Building Locally

Run the following:

```
bundle exec rake "generate_image[heroku-18]"
bundle exec rake "new[9.3.0.0,heroku-18]"
bash rubies/heroku-18/ruby-2.6.8-jruby-9.3.0.0.sh
bundle exec rake "upload[9.3.0.0,2.6.8,heroku-18]"
```

You can replace `heroku-18` and `9.2.8.0` with any stack and JRuby version.
test

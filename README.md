# JRuby Build Scripts

A set of scripts used to build JRuby packages for Heroku

## Building Locally

Make sure you've generated a docker image:

```
bundle exec rake "generate_image[heroku-18]"
```

Then run the following:

```
bundle exec rake "new[9.3.0.0,heroku-18]" &&
bash rubies/heroku-18/ruby-2.6.8-jruby-9.3.0.0.sh &&
bundle exec rake "upload[9.3.0.0,2.6.8,heroku-18]" &&
echo "Done building jruby 9.3.0.0 for heroku-18"
```

You can replace `heroku-18` and `9.2.8.0` with any stack and JRuby version.

require 'fileutils'
require 'uri'
require 'net/http'

S3_BUCKET_NAME = "heroku-buildpack-ruby"

# JRuby targets a specific Ruby stdlib version, for example JRuby 9.4.3.0 implements Ruby 3.1.4 stdlib
#
# This method parses an XML file based on the input jruby version to determine what Ruby version
# it targets.
#
# When people use jruby they specify it in their gemfile like this:
#
# ```
#   # Gemfile
#   ruby "3.1.4", engine: "jruby", engine_version: "9.4.3.0"
# ```
def ruby_stdlib_version(jruby_version: )
  uri = URI("https://raw.githubusercontent.com/jruby/jruby/#{jruby_version}/default.build.properties")
  default_props = Net::HTTP.get(uri)
  ruby_version = default_props.match(/^version\.ruby=(.*)$/)[1]
  if ruby_version.nil? || ruby_version.empty?
    raise "Could not find Ruby StdLib version for jruby #{jruby_version} from #{uri}!"
  end

  ruby_version
end

# Writes a shell script to disk for the given inputs
#
# This script is a convienece wrapper for calling `docker run`
def write_shell_script(stack: , jruby_version: , ruby_stdlib_version: )
  source_folder = "rubies/#{stack}"
  FileUtils.mkdir_p(source_folder)

    file = "#{source_folder}/jruby-#{jruby_version}.sh"
    puts "Writing #{file}"
    File.open(file, 'w') do |file|
      file.puts <<~FILE
        #!/bin/sh

        # Sets OUTPUT_DIR, CACHE_DIR, and STACK
        source `dirname $0`/../common.sh
        source `dirname $0`/common.sh

        docker run -v $OUTPUT_DIR:/tmp/output -v $CACHE_DIR:/tmp/cache -e VERSION=#{jruby_version} -e RUBY_VERSION=#{ruby_stdlib_version} -t hone/jruby-builder:$STACK
      FILE
    end
end

desc "Emits a changelog message"
task :changelog, [:version] do |_, args|
  jruby_version = args[:version]
  ruby_stdlib_version = ruby_stdlib_version(jruby_version: jruby_version)

  puts "Add a changelog item: https://devcenter.heroku.com/admin/changelog_items/new"

  puts <<~EOM

    ## JRuby version #{jruby_version} is now available

    [JRuby v#{jruby_version}](/articles/ruby-support#ruby-versions) is now available on Heroku. To run
    your app using this version of Ruby, add the following `ruby` directive to your Gemfile:

    ```ruby
    ruby "#{ruby_stdlib_version}", engine: "jruby", engine_version: "#{jruby_version}"
    ```

    The JRuby release notes can be found on the [JRuby website](https://www.jruby.org/news).

  EOM
end

desc "Generate new jruby shell scripts"
task :new, [:version, :stack] do |t, args|
  stack = args[:stack]
  jruby_version = args[:version]

  # JRuby 9000
  if (cmp_ver = Gem::Version.new(jruby_version)) <= Gem::Version.new("1.8.0")
    raise "Unsupported version, too old #{jruby_version}"
  else
    ruby_stdlib_version = ruby_stdlib_version(jruby_version: jruby_version)

    write_shell_script(
      stack: stack,
      jruby_version: jruby_version,
      ruby_stdlib_version: ruby_stdlib_version,
    )
  end
end

desc "Upload a ruby to S3"
task :upload, [:version, :stack] do |t, args|
  require 'aws-sdk-s3'
  stack = args[:stack]
  jruby_version = args[:version]
  ruby_stdlib_version = ruby_stdlib_version(jruby_version: jruby_version)

  filename = "ruby-#{ruby_stdlib_version}-jruby-#{jruby_version}.tgz"
  profile_name = "#{S3_BUCKET_NAME}#{args[:staging] ? "-staging" : ""}"
  s3_key = "#{stack}/#{filename.sub(/-(preview|rc)\d+/, '')}"
  output_file  = "builds/#{stack}/#{filename}"

  if File.exists?(output_file)
    puts "Uploading #{output_file} to s3://#{profile_name}/#{s3_key}"
  else
    raise "Filename #{output_file} does not exist"
  end

  s3 = Aws::S3::Resource.new(
    region: "us-east-1",
    access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
    secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
    session_token: ENV.fetch("AWS_SESSION_TOKEN")
  )
  bucket       = s3.bucket(profile_name)
  s3_object    = bucket.object(s3_key)

  File.open(output_file, 'rb') do |file|
    s3_object.put(body: file, acl: "public-read")
  end
end

desc "Build docker image for stack"
task :generate_image, [:stack] do |t, args|
  stack = args[:stack]

  FileUtils.cp("dockerfiles/Dockerfile.#{stack}", "Dockerfile")
  system("docker build -t hone/jruby-builder:#{stack} .")
  FileUtils.rm("Dockerfile")
end

desc "Test images"
task :test, [:version, :ruby_version, :stack] do |t, args|
  require 'tmpdir'
  require 'okyakusan'
  require 'rubygems/package'
  require 'zlib'

  def system_pipe(command)
    IO.popen(command) do |io|
      while data = io.read(16) do
        print data
      end
    end
  end

  def gemfile_ruby(ruby_version, engine, engine_version)
    %Q{ruby "#{ruby_version}", :engine => "#{engine}", :engine_version => "#{engine_version}"}
  end

  def network_retry(max_retries, retry_count = 0)
    yield
  rescue Errno::ECONNRESET, EOFError
    if retry_count < max_retries
      $stderr.puts "Retry Count: #{retry_count}"
      sleep(0.01 * retry_count)
      retry_count += 1
      retry
    end
  end

  tmp_dir  = Dir.mktmpdir
  app_dir  = "#{tmp_dir}/app"
  app_tar  = "#{tmp_dir}/app.tgz"
  app_name = nil
  web_url  = nil
  FileUtils.mkdir_p("#{tmp_dir}/app")

  begin
    system_pipe("git clone --depth 1 https://github.com/sharpstone/jruby-minimal.git #{app_dir}")
    exit 1 unless $?.success?

    ruby_line = gemfile_ruby(args[:ruby_version], "jruby", args[:version])
    puts "Setting ruby version: #{ruby_line}"
    text = File.read("#{app_dir}/Gemfile")
    text.sub!(/^\s*ruby.*$/, ruby_line)
    File.open("#{app_dir}/Gemfile", 'w') {|file| file.print(text) }

    lines = File.readlines("#{app_dir}/Gemfile.lock")
    File.open("#{app_dir}/Gemfile.lock", 'w') do |file|
      lines.each do |line|
        next if line.match(/RUBY VERSION/)
        next if line.match(/ruby (\d+\.\d+\.\d+p\d+) \(jruby \d+\.\d+\.\d+\.\d+\)/)
        file.puts line
      end
    end

    Dir.chdir(app_dir) do
      puts "Packaging app"
      system_pipe("tar czf #{app_tar} *")
      exit 1 unless $?.success?
    end

    Okyakusan.start do |heroku|
      # create new app
      response = heroku.post("/apps", data: {
        stack: args[:stack]
      })

      if response.code != "201"
        $sterr.puts "Error Creating Heroku App (#{resp.code}): #{resp.body}"
        exit 1
      end
      json     = JSON.parse(response.body)
      app_name = json["name"]
      web_url  = json["web_url"]

      # upload source
      response = heroku.post("/apps/#{app_name}/sources")
      if response.code != "201"
        $stderr.puts "Couldn't get sources to upload code."
        exit 1
      end

      json = JSON.parse(response.body)
      source_get_url = json["source_blob"]["get_url"]
      source_put_url = json["source_blob"]["put_url"]

      puts "Uploading data to #{source_put_url}"
      uri = URI(source_put_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
        request = Net::HTTP::Put.new(uri.request_uri, {
          'Content-Length'   => File.size(app_tar).to_s,
          # This is required, or Net::HTTP will add a default unsigned content-type.
          'Content-Type'      => ''
        })
        begin
          app_tar_io          = File.open(app_tar)
          request.body_stream = app_tar_io
          response            = http.request(request)
          if response.code != "200"
            $stderr.puts "Could not upload code"
            exit 1
          end
        ensure
          app_tar_io.close
        end
      end

      # create build
      response = heroku.post("/apps/#{app_name}/builds", version: "3.streaming-build-output", data: {
        "source_blob" => {
          "url"     => source_get_url,
          "version" => ""
        }
      })
      if response.code != "201"
        $stderr.puts "Could create build"
        exit 1
      end

      # stream build output
      uri = URI(JSON.parse(response.body)["output_stream_url"])
      Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http.request(request) do |response|
          response.read_body do |chunk|
            print chunk
          end
        end
      end
    end

    # test app
    puts web_url
    sleep(1)
    response = network_retry(20) do
      Net::HTTP.get_response(URI(web_url))
    end

    if response.code != "200"
      $stderr.puts "App did not return a 200: #{response.code}"
      exit 1
    else
      puts response.body
      puts "Deleting #{app_name}"
      Okyakusan.start {|heroku| heroku.delete("/apps/#{app_name}") if app_name }
    end
  ensure
    FileUtils.remove_entry tmp_dir
  end
end

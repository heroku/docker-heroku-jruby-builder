#!/usr/bin/env bash

set -euo pipefail

workspace_dir="$1"
output_dir="$2"
cache_dir="$3"

jruby_bin_file="jruby-dist-$VERSION-bin.tar.gz"

if [ -f "$cache_dir/$jruby_bin_file" ]; then
	echo "Using cached $jruby_bin_file"
else
	echo "Downloading $jruby_bin_file"
	curl -s -L -o "$cache_dir/$jruby_bin_file" "https://repo1.maven.org/maven2/org/jruby/jruby-dist/$VERSION/$jruby_bin_file"
fi

echo "Extracting $jruby_bin_file"
tar -xvf "$cache_dir/$jruby_bin_file" -C "$workspace_dir" --strip-components=1

echo "Preparing for Heroku"

rm "$workspace_dir"/bin/*.bat
rm "$workspace_dir"/bin/*.dll
rm "$workspace_dir"/bin/*.exe
rm -rf "$workspace_dir"/lib/target

# Ensure a bin/ruby binary exists
cd "$workspace_dir/bin"; ln -s "jruby" "ruby"; cd -

tgz_filename="ruby-$RUBY_STDLIB_VERSION-jruby-$VERSION.tgz"
echo "Packaging $tgz_filename"

cd "$workspace_dir"
mkdir -p "$output_dir/$BASE_IMAGE/amd64"
tar --exclude "$(find lib/jni/* -maxdepth 1 -not -name x86_64-Linux)" \
	-czf "$output_dir/$BASE_IMAGE/amd64/$tgz_filename" bin/ lib/

mkdir -p "$output_dir/$BASE_IMAGE/arm64"

tar --exclude "$(find lib/jni/* -maxdepth 1 -not -name aarch64-Linux)" \
	-czf "$output_dir/$BASE_IMAGE/arm64/$tgz_filename" bin/ lib/
cd -

# Support stacks prior to heroku-24
cp "$output_dir/$BASE_IMAGE/amd64/$tgz_filename" \
	"$output_dir/$BASE_IMAGE/$tgz_filename"

ls "$output_dir/$BASE_IMAGE"
ls "$output_dir/$BASE_IMAGE/arm64"
ls "$output_dir/$BASE_IMAGE/amd64"

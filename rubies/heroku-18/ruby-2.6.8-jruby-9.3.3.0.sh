#!/bin/sh

source `dirname $0`/../common.sh
source `dirname $0`/common.sh

docker run -v $OUTPUT_DIR:/tmp/output -v $CACHE_DIR:/tmp/cache -e VERSION=9.3.3.0 -e RUBY_VERSION=2.6.8 -t hone/jruby-builder:$STACK

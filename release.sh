#!/bin/bash
set -e

mkdir -p tmp/

NODE_ENV=production npm run deploy --prefix assets
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
tar czf ./tmp/bygg_app.tar.gz _build/prod/rel/bygg_app/
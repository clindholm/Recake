#!/bin/bash
mkdir -p tmp/

NODE_ENV=production npm run deploy --prefix assets
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
cd _build/prod/rel/recake/
tar czf ../../../../tmp/recake.tar.gz .

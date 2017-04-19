#!/bin/sh

# Wrapper to start the correct owncloud binary with proper preinitializations.
qtdir=ownCloud/Qt-5.6.2
export LD_LIBRARY_PATH=/opt/$qtdir/lib64

exec /opt/$qtdir/bin/owncloud "$@"

# end

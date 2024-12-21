#!/bin/bash

# Fix for Rancher Desktop on Mac.
# when you get errors along the lines of:
# `Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?`

# The Administrative Access enabled via the Preferences
# that is supposed to fix this does not seem to work.

# ref: https://github.com/docker/docker-py/issues/3059
#
# NOTE: Sometimes this also doesn't work, in that case you can try a factory reset from Rancher Desktop.

sudo ln -s $HOME/.rd/docker.sock /var/run/docker.sock

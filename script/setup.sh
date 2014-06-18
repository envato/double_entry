#!/bin/bash

echo "This command will setup your local dev environment, including"
echo "  * bundle install"
echo

echo "Bundling..."
bundle install --binstubs bin --path .bundle

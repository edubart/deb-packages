#!/bin/bash
set -e

# Test rollup
rollup-http-server --help > /dev/null 2>&1
rollup --help > /dev/null 2>&1

echo cartesi-machine-guest-tools OK!

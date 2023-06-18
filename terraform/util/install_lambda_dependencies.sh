#!/bin/bash

#https://repost.aws/knowledge-center/lambda-python-package-compatible

# pip --version
#if older than 19.3.0
# python3.9 -m pip install --upgrade pip

pip install \
    --platform manylinux2014_x86_64 \
    --target $path_module/src \
    --implementation cp \
    --python $runtime \
    --only-binary=:all: --upgrade \
    -r $path_module/src/requirements.txt
#!/bin/bash

#https://repost.aws/knowledge-center/lambda-python-package-compatible

pip install \
    --platform manylinux2014_x86_64 \
    --target $path_module/src \
    --implementation cp \
    --python $runtime \
    --only-binary=:all: --upgrade \
    -r $path_module/src/requirements.txt
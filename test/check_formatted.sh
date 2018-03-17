#!/bin/bash

if [[ $(mix help format) ]];
then
    mix format --check-formatted
else
    exit 0
fi


#!/usr/bin/env bash

env=""
case $2 in
    "dev")
        env="development"
        ;;
    "tst")
        env="test"
        ;;
    "prd")
        env="production"
        ;;
esac

sed -i "/$1/d" ~/Workspace/homepage-webserver-ansible/inventory/${env}

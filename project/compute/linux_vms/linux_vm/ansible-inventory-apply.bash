#!/usr/bin/env bash

if [[ -z $1 ]]; then
    exit 1
fi

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

if [ "$3" = "nginx" ]; then
    sed -i -E "/[servers]|[nginx]/a $1" ~/Workspace/homepage-webserver-ansible/inventory/${env}
else
    sed -i "/[servers]/a $1" ~/Workspace/homepage-webserver-ansible/inventory/${env}
fi

if [[ -z ${ip} ]]; then
    exit 1
fi

cat << EOF >> ~/.ssh/config
# ${name}
Host ${host}
    HostName ${ip}
    User ${user}
    IdentityFile ${identityfile}

EOF

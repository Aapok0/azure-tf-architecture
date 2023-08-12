cat << EOF >> ~/.ssh/config
# ${name}
Host ${host}
    HostName ${ip}
    User ${user}
    IdentityFile ${identityfile}

EOF

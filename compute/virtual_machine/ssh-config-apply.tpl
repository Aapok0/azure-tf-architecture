{* Add virtual machine's host information to ssh config *}
cat << EOF >> ~/.ssh/config
# ${name}
Host ${host}
    HostName ${ip}
    User ${user}
    IdentityFile ${identityfile}

EOF

{* Add virtual machine's ip to Ansible inventory *}
if [ ${service} = "nginx" ]; then
    sed -i -E '/[servers]|[nginx]/a ${ip}' ~/Workspace/homepage-webserver-ansible/inventory/production
else
    sed -i '/[servers]/a ${ip}' ~/Workspace/homepage-webserver-ansible/inventory/production
fi

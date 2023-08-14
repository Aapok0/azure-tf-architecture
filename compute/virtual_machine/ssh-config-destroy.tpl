{* Remove virtual machine's host information from ssh config *}
cat ~/.ssh/config > ~/.ssh/config.bak

cp ~/.ssh/config ~/.ssh/config.tmp
sed -i '/${name}/,+6d' ~/.ssh/config.tmp > ~/.ssh/config

rm ~/.ssh/config.tmp

{* Remove virtual machine's ip from Ansible inventory *}
sed -i '/${ip}/d' ~/Workspace/homepage-webserver-ansible/inventory/production

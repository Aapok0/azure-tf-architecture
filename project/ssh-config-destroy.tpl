cat ~/.ssh/config > ~/.ssh/config.bak

cp ~/.ssh/config ~/.ssh/config.tmp
sed -i '/${name}/,+6d' ~/.ssh/config.tmp > ~/.ssh/config

rm ~/.ssh/config.tmp

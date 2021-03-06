#!/bin/bash
echo "running 50npm.sh"
. /opt/elasticbeanstalk/env.vars
function error_exit
{
  echo "exiting with error"
  eventHelper.py --msg "$1" --severity ERROR
  exit $2
}

#redirect all output to cfn-init to capture it by log.io
exec >>/var/log/cfn-init.log  2>&1
echo "------------------------------ — Setting up NPM directory! — ---------------------------------------"

#avoid long NPM fetch hangups
npm config set fetch-retry-maxtimeout 15000

#install not-installed yet app node_modules
echo "linking NPM modules to /var/node_modules"
if [ ! -d "/var/node_modules" ]; then
  mkdir /var/node_modules ;
fi
if [ -d /tmp/deployment/application ]; then
  ln -s /var/node_modules /tmp/deployment/application/
fi

if [ ! -L /usr/bin/yarn ]; then
        # install yarn
        echo "installing yarn"
        sudo wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo
        curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
        sudo yum -y install yarn
else
        echo "yarn already found, not installing"
fi

echo yarn version = `yarn --version`

# echo "------------------------------ — Installing/updating NPM modules, it might take a while, go take a leak or have a healthy snack... — -----------------------------------"
# cd /tmp/deployment/application
# /opt/elasticbeanstalk/node-install/node-v$NODE_VER-linux-$ARCH/bin/npm install node-sass
# OUT=$([ -d "/tmp/deployment/application" ] && cd /tmp/deployment/application && /opt/elasticbeanstalk/node-install/node-v$NODE_VER-linux-$ARCH/bin/npm install --production) || error_exit "Failed to run npm install.  $OUT" $?
# echo $OUT
echo "------------------------------ — Installing/updating NPM modules with YARN (And making sure node-sass is installed with NPM) — -----------------------------------"
cd /tmp/deployment/application
OUT=$([ -d "/tmp/deployment/application" ] && cd /tmp/deployment/application && /usr/bin/yarn install --production)  && npm install node-sass|| error_exit "Failed to run yarn install.  $OUT" $?
echo $OUT


chmod -R o+r /var/node_modules

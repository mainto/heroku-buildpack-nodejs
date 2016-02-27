needs_resolution() {
  local semver=$1
  if ! [[ "$semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

install_nodejs() {
  local version="$1"
  local dir="$2"

  if needs_resolution "$version"; then
    echo "Resolving node version ${version:-(latest stable)} via semver.io..."
    local version=$(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=${version}" https://semver.herokuapp.com/node/resolve)
  fi

  echo "Downloading and installing node $version..."
  local versionfolder=$(echo $version| cut -d'.' -f 1,2)
  local download_url="https://deb.nodesource.com/node_$versionfolder/pool/main/n/nodejs/nodejs_$version-1nodesource1~trusty1_armhf.deb"
  curl "$download_url" --silent --fail  --retry 5 --retry-max-time 15 -o /tmp/node.deb || (echo "Unable to download node $version; does it exist?" && false)
  rm -rf /tmp/node
  mkdir /tmp/node
  ar p /tmp/node.deb data.tar.xz | unxz | tar x -C /tmp/node
  mv /tmp/node/usr/bin/nodejs /tmp/node/usr/bin/node
  rm -rf $dir/*
  mv /tmp/node/usr/* $dir
  chmod +x $dir/bin/*

  local old_node="^#!.*$"
  local new_node="#!$dir/bin/node"
  local file=$dir/bin/npm
  sed -i --follow-symlinks "s@$old_node@$new_node@" $file
}

install_iojs() {
  local version="$1"
  local dir="$2"

  if needs_resolution "$version"; then
    echo "Resolving iojs version ${version:-(latest stable)} via semver.io..."
    version=$(curl --silent --get  --retry 5 --retry-max-time 15 --data-urlencode "range=${version}" https://semver.herokuapp.com/iojs/resolve)
  fi

  echo "Downloading and installing iojs $version..."
  local versionfolder=$(echo $version| cut -d'.' -f 1)
  local download_url="https://deb.nodesource.com/iojs_$versionfolder.x/pool/main/i/iojs/iojs_$version-1nodesource1~trusty1_armhf.deb"
  curl "$download_url" --silent --fail --retry 5 --retry-max-time 15 -o /tmp/node.deb || (echo "Unable to download iojs $version; does it exist?" && false)
  rm -rf /tmp/node
  mkdir /tmp/node
  ar p /tmp/node.deb data.tar.xz | unxz | tar x -C /tmp/node
  rm -rf $dir/*
  mv /tmp/node/usr/* $dir
  chmod +x $dir/bin/*

  local old_node="^#!.*$"
  local new_node="#!$dir/bin/node"
  local file=$dir/bin/npm
  sed -i --follow-symlinks "s@$old_node@$new_node@" $file
}

install_npm() {
  local version="$1"
  local dir="$2"

  if [ "$version" == "" ]; then
    echo "Using default npm version: `npm --version`"
  else
    if needs_resolution "$version"; then
      echo "Resolving npm version ${version} via semver.io..."
      version=$(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=${version}" https://semver.herokuapp.com/npm/resolve)
    fi
    if [[ `npm --version` == "$version" ]]; then
      echo "npm `npm --version` already installed with node"
    else
      echo "Downloading and installing npm $version (replacing version `npm --version`)..."
      npm install --unsafe-perm --quiet -g npm@$version 2>&1 >/dev/null
      local old_node="^#!.*$"
      local new_node="#!$dir/bin/node"
      local file=$dir/bin/npm
      sed -i --follow-symlinks "s@$old_node@$new_node@" $file
    fi
  fi
}

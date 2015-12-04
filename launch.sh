#!/usr/bin/env bash

# VARIABLES --------------------------------------------------------------------

THIS_DIR=$(cd $(dirname $0); pwd)
#THIS_DIR="${0%/*}"
cd $THIS_DIR

# FUNCTIONS --------------------------------------------------------------------

update() {
  git pull
  git submodule update --init --recursive
  install_rocks
}

# Will install luarocks on THIS_DIR/.luarocks
install_luarocks() {
  git clone https://github.com/keplerproject/luarocks.git
  cd luarocks
  git checkout tags/v2.2.1 # Current stable

  PREFIX="$THIS_DIR/.luarocks"

  ./configure --prefix=$PREFIX --sysconfdir=$PREFIX/luarocks --force-config

  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  make build && make install
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  cd ..
  rm -rf luarocks
}

install_rocks() {
  ./.luarocks/bin/luarocks install luasocket
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install oauth
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install redis-lua
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install lua-cjson
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install fakeredis
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install xml
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install feedparser
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi

  ./.luarocks/bin/luarocks install serpent
  RET=$?
  if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi
}

install() {
  git pull
  git submodule update --init --recursive
  patch -i "patches/lua-tg.get_message.block_user.res_user.export_chat_link.patch" -p 0 -Nt
  RET=$?;

  cd tg
  if [ $RET -ne 0 ]; then
    autoconf -i
  fi
  ./configure --enable-liblua --enable-json --disable-python && make

  RET=$?; if [ $RET -ne 0 ]; then
    printf "%s\n" "Error. Exiting."
    exit $RET
  fi
  cd ..
  install_luarocks
  install_rocks
}

# MAIN -------------------------------------------------------------------------

if [ "$1" = "install" ]; then
  install
elif [ "$1" = "update" ]; then
  update
else
  if [ ! -f ./tg/telegram.h ]; then
    printf "%s\n" "tg not found"
    printf "%s\n" "Run $0 install"
    exit 1
  fi

  if [ ! -f ./tg/bin/telegram-cli ]; then
    printf "%s\n" "tg binary not found"
    printf "%s\n" "Run $0 install"
    exit 1
  fi

  ./tg/bin/telegram-cli -k ./tg/tg-server.pub -s ./bot/bot.lua -l 1 -E $@
fi

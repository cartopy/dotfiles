#!/bin/bash

# change version you want to install on local
TMUX_VERSION=2.7
LIBEVENT_VERSION=2.1.8
NCURSES_VERSION=6.1

# based on https://gist.github.com/ryin/3106801#gistcomment-2191503
# tmux will be installed in $HOME/.local/bin if you specify to install without root access
# It's assumed that wget and a C/C++ compiler are installed.

################################################################
set -e

case "$OSTYPE" in
    solaris*) platform='SOLARIS' ;;
    darwin*)  platform='OSX' ;;
    linux*)   platform='LINUX' ;;
    bsd*)     platform='BSD' ;;
    msys*)    platform='WINDOWS' ;;
    *)        platform='unknown: $OSTYPE' ;;
esac

if [[ $$ = $BASHPID ]]; then
    if [[ $platform == "OSX" ]]; then
        PROJ_HOME=$(cd $(echo $(dirname $0) | xargs greadlink -f ); cd ..; pwd)
    elif [[ $platform == "LINUX" ]]; then
        PROJ_HOME=$(cd $(echo $(dirname $0) | xargs readlink -f ); cd ..; pwd)
    fi
    TMP_DIR=$HOME/tmp_install

    if [ ! -d $HOME/.local/bin ]; then
        mkdir -p $HOME/.local/bin
    fi

    if [ ! -d $HOME/.local/src ]; then
        mkdir -p $HOME/.local/src
    fi

    if [ ! -d $TMP_DIR ]; then
        mkdir -p $TMP_DIR
    fi
fi

setup_func() {
    if [[ $1 = local ]]; then
        echo 'Build "libevent-dev" and "libncurses-dev".' >&2

        # libevent
        if [ -d $HOME/.local/src/libevent-* ]; then
            cd $HOME/.local/src/libevent-*
            make uninstall
            cd ..
            rm -rf $HOME/.local/src/libevent-*
        fi
        cd $TMP_DIR
        wget https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz 
        tar -xvzf libevent-${LIBEVENT_VERSION}-stable.tar.gz
        cd libevent-${LIBEVENT_VERSION}-stable
        ./configure --prefix=$HOME/.local --disable-shared
        make
        make install
        cd $TMP_DIR
        mv libevent-${LIBEVENT_VERSION}-stable $HOME/.local/src

        # ncurses
        if [ -d $HOME/.local/src/ncurses-* ]; then
            cd $HOME/.local/src/ncurses-*
            make uninstall
            cd ..
            rm -rf $HOME/.local/src/ncurses-*
        fi
        cd $TMP_DIR
        wget http://invisible-island.net/datafiles/release/ncurses.tar.gz
        tar -xvzf ncurses.tar.gz
        cd ncurses-${NCURSES_VERSION}
        ./configure --prefix=$HOME/.local
        make
        make install
        cd $TMP_DIR
        mv ncurses-${NCURSES_VERSION} $HOME/.local/src
    else
        if [[ $platform == "OSX" ]]; then
            brew install libevent ncurses
            brew install wget
            brew uninstall tmux
        elif [[ $platform == "LINUX" ]]; then
            sudo apt-get -y install libevent-dev libncurses-dev
            sudo apt-get -y remove tmux
        else
            print 'Not defined'
        fi
    fi

    if [[ $1 == local ]]; then
        if [ -d $HOME/.local/src/tmux-* ]; then
            cd $HOME/.local/src/tmux-*
            make uninstall
            cd ..
            rm -rf $HOME/.local/src/tmux-*
        fi
        cd $TMP_DIR
        wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
        tar -xvzf tmux-${TMUX_VERSION}.tar.gz
        cd tmux-${TMUX_VERSION}
        # ./configure CFLAGS="-I$HOME/.local/include -I$HOME/.local/include/ncurses" LDFLAGS="-L$HOME/.local/lib -L$HOME/.local/include/ncurses -L$HOME/.local/include"
        # CPPFLAGS="-I$HOME/.local/include -I$HOME/.local/include/ncurses" LDFLAGS="-static -L$HOME/.local/include -L$HOME/.local/include/ncurses -L$HOME/.local/lib" make
        # mv tmux $HOME/.local/bin
        ./configure --prefix=$HOME/.local
        make
        make install
        cd $TMP_DIR
        mv tmux-${TMUX_VERSION} $HOME/.local/src
    else
        if [[ $platform == "OSX" ]]; then
            brew install tmux
        elif [[ $platform == "LINUX" ]]; then
            if [ -d /usr/local/src/tmux-* ]; then
                cd /usr/local/src/tmux-*
                sudo make uninstall
                cd ..
                sudo rm -rf /usr/local/src/tmux-*
            fi
            cd $TMP_DIR
            wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
            tar -xvzf tmux-${TMUX_VERSION}.tar.gz
            cd tmux-${TMUX_VERSION}
            ./configure
            make
            sudo make install
            cd $TMP_DIR
            sudo mv tmux-${TMUX_VERSION} /usr/local/src
        else
            echo "[!] $platform is not supported."; exit 1
        fi
    fi

    # clean up
    if [[ $$ = $BASHPID ]]; then
        rm -rf $TMP_DIR
    fi

    echo "[*] tmux installed..."
}


while true; do
    echo
    read -p "[?] Do you wish to install tmux? " yn
    case $yn in
        [Yy]* ) :; ;;
        [Nn]* ) echo "[!] Aborting install tmux..."; break;;
        * ) echo "Please answer yes or no."; continue;;
    esac

    echo
    read -p "[?] Install locally or sytemwide? " yn
    case $yn in
        [Ll]ocal* ) echo "[*] Install tmux locally..."; setup_func 'local'; break;;
        [Ss]ystem* ) echo "[*] Install tmux systemwide..."; setup_func; break;;
        * ) echo "Please answer locally or systemwide."; continue;;
    esac
done
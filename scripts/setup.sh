#!/bin/bash

source ../dirs
CONFIG=$CONFIG_PATH

### CREATE SYMLINKS ###
create_symlink(){
 local target=$1
 local shortcut=$2
 rm -rf $shortcut
 ln -s $target $shortcut
}

create_symlink $CONFIG/.gitconfig ~/.gitconfig 
create_symlink $CONFIG/.vim ~/.vim
create_symlink $CONFIG/.vimrc ~/.vimrc

### CLONE APPS ###
clone_app(){
 (cd $BASH_APPS_PATH && git clone $1)
}

# z
clone_app https://github.com/rupa/z.git

# liquiprompt
clone_app https://github.com/nojhan/liquidprompt.git

### Bash settings ###
# shopt
shopt -s cdspell
shopt -s nocaseglob

### Python libs and apps ###
sudo apt install python-dev python3-dev python3-pip

# fuck
sudo -H pip3 install thefuck

# glances
sudo pip install glances

### SETTINGS ###

# Default settings
HISTSIZE=99999
HISTFILESIZE=99999

# LOG LVL: 0 - info, 1 - warn, 2 - error
LOG_LVL_DEBUG=0
LOG_LVL_INFO=1
LOG_LVL_WARN=2
LOG_LVL_ERROR=3
CURRENT_LOG_LVL=$LOG_LVL_INFO

### EXPORTS ###
export TERM='xterm-256color'

### ALIASES ###
alias ll='ls -alh'
alias l.='ls -d .*'
alias ll.='ls -lhd .*'
alias du='du -h'

# net aliases
alias ports='netstat -tulanp'
alias ping='ping -c 5'

######################
##  MAIN FUNCTIONS  ##
######################

### Echos ###
__echo_pretty(){
 [[ "$1" == "-h" ]] && __echo_info "decorated echo" && return
 local text=$1
 [[ $CURRENT_LOG_LVL -le $LOG_LVL_DEBUG ]] && echo "### $text ###"
}

__echo_arrow(){
 local text=$1
 echo "--> $text"
}

__echo_debug(){
  [[ "$1" == "-h" ]] && __echo_info "Echo in white" && return
 [[ $CURRENT_LOG_LVL -le $LOG_LVL_DEBUG ]] && echo "$@"
}

__echo_info(){
 [[ "$1" == "-h" ]] && __echo_info "Echo in blue" && return
 local color=`tput setaf 4`
 local reset=`tput sgr0`
 [[ $CURRENT_LOG_LVL -le $LOG_LVL_INFO ]] && echo "${color}$@${reset}"
}

__echo_ok(){
 [[ "$1" == "-h" ]] && __echo_info "Echo in green" && return
 local color=`tput setaf 2`
 local reset=`tput sgr0`
 [[ $CURRENT_LOG_LVL -le $LOG_LVL_INFO ]] && echo "${color}$@${reset}"
}

__echo_warn(){
 [[ "$1" == "-h" ]] && __echo_info "Echo in yellow" && return
 local color=`tput setaf 11`
 local reset=`tput sgr0`
 [[ $CURRENT_LOG_LVL -le $LOG_LVL_WARN ]] && echo "${color}$@${reset}"
}

__echo_err(){
 [[ "$1" == "-h" ]] && __echo_info "Echo in red" && return
 local color=`tput setaf 1`
 local reset=`tput sgr0`
 [[ $CURRENT_LOG_LVL -le $LOG_LVL_ERROR ]] && echo "${color}$@${reset}"
}

### Helps and checks ###
__show_help(){
  __check $1 "Funciton name that is translated to related variable name"
  local help_variable_name=`echo $1 | tr - _`
  # local help_message=${!help_variable_name} # bash
  local help_message=${(P)help_variable_name}
  [[ ! -z $help_message ]] && __echo_info $help_message || __echo_err "Help message unavailable"
}

__generate_help(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  grep -rh "() *{" $1| tr -d " " | tr -d "(){" | xargs -I [] echo -e "[]=''" | tr - _ >> help.sh
}

__check(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  [[ "$#" -eq 1 ]] && __echo_err "$1 is not set!"
}

### Other functions ###
__show_popup(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  zenity --info --text "$1"
}

__pathadd() {
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
    if [[ -d "$1" ]] && ! echo $PATH | grep -E -q "(^|:)$1($|:)" ; then
      [[ "$2" = "after" ]] && PATH="$PATH:${1%/}" || PATH="${1%/}:$PATH"
    fi
}

__pathrm() {
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  PATH="$(echo $PATH | sed -e "s;\(^\|:\)${1%/}\(:\|\$\);\1\2;g" -e 's;^:\|:$;;g' -e 's;::;:;g')"
}

__source_if_exists(){
 local file=$1
 if [[ -f $file ]]
  then
   source $file
   __echo_debug "--> Sourced $file"
  else
   __echo_err "--> Cannot source $file"
 fi
}

__join(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  __check $1 "delimiter"
  local IFS="$1"; shift; echo "$*";
}

__git_add_commit_folder(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
 __check $1 "folder name"
 local folder_name=$1
 local modified_files=`(cd $1 && git ls-files -m)`
 if [[ $modified_files ]]
  then
    local joined_modified_files=`__join "," $modified_files`
    local git_message="Update: $joined_modified_files"
    git -C $folder_name commit -a -m "$git_message"
    __echo_info "$git_message"
  else
    __echo_warn "Nothing to commit."
 fi
}

__ssh_cert(){
 [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
 local username=$1
 local host=$2
 local cert_path=$3
 ssh -i $cert_path $username@$host
}

__scp_cert(){
 [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
 local username=$1
 local host=$2
 local cert_path=$3
 local path=$4
 scp -i $cert_path $username@$host:$path .
}

__print_column(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  local delimiter=$1
  local column=$2
  tr -s "$delimiter" | cut -d "$delimiter" -f $column
}

### OPENCONNECT VPN ###
__openconnect_vpn(){
 [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
 local user=$1
 local vpn_url=$2
 local params=$3
 sudo openconnect -u $user $vpn_url $params
}

__openconnect_vpn_kill_signal(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  local signal=$1
  local pattern=$2
  local PS=`ps aux | grep "sudo openconnect" | grep $pattern | awk '{print $2}' | head -1`
  if [[ $PS ]]
   then
    __echo_ok "$signal for VPN: $pattern"
    sudo kill -$signal $PS
   else __echo_err "Not connected to VPN: $pattern"
  fi
}

######################
## INITIAL SOURCING ##
######################
# source paths to main directories and help
MAIN_PATH=~/shell_config
source $MAIN_PATH/dirs.sh
source $MAIN_PATH/help.sh

__source_forward_declarations(){
  [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
  grep -rh "() *{" $SHELL_MODULES_PATH | tr -d " " | xargs -I {} echo -e "{}\n:\n}" > $SHELL_FWD_PATH
  source $SHELL_FWD_PATH
}
__source_forward_declarations

######################
## MODULES SOURCING ##
######################
__echo_pretty "Sourcing modules:"
__source_modules_aliases(){
 [[ "$1" == "-h" ]] && __show_help $funcstack[1] && return
 for file in $(find $SHELL_MODULES_PATH -type f -name help.sh); do __source_if_exists "$file"; done
 for file in $(find $SHELL_MODULES_PATH -type f -name aliases.sh); do __source_if_exists "$file"; done
}
__source_modules_aliases

### PATH AND AUTOSTART ###
__echo_pretty "Sourcing path and autostart:"
__source_if_exists $SHELL_PATH_FILE
__source_if_exists $SHELL_AUTOSTART_PATH

### APPS ###
__echo_pretty "Sourcing apps:"
# z -> https://github.com/rupa/z.git
__source_if_exists $SHELL_APPS_PATH/z/z.sh

# liquidprompt -> https://github.com/nojhan/liquidprompt.git
[[ $- = *i* ]] && source $SHELL_APPS_PATH/liquidprompt/liquidprompt

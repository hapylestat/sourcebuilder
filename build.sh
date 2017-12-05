#!/bin/bash 
######################################
#            Shell script            #
# Author: H.L.                       #
# TPL Version: 0.1                   #
######################################

#========================Global variables
APPVER="0.1b"
#=======================Include base library

. /etc/system.conf
. $libROOT/functions

MODDIR="mods"

include terminal,filesystem,system
include lib.system.args

EXITONERROR=1

if [ ! -z ${ARGS["noservice"]} ]; then
  include lib.disableservice
fi

do_list(){
 include $MODDIR.$1
 write_item "$1" "$APPNAME $APPVER"
}

# $1  - dir to list, else list all
go_list(){
 if [ ! -z $1 ]; then
   if [ -f "$MODDIR/$1" ]; then
     do_list $1
   fi
 else
   dirlist_callback do_list "$MYDIR/$MODDIR" "."
 fi
}


# $1 - pkg
# $2 - ver
set_env(){
 unset APPNAME APPVER CURRVER EXTERNAL_DEP INTERNAL_DEP
 include $MODDIR.$1
 if [ ! -z $2 ]; then
  APPVER=$2
 fi
}

# $1 - app
# $2 - ver
go_build(){
 set_env $1 $2
 
 write_info "Installing deps for $APPNAME  $APPVER"
 if [ "x$EXTERNAL_DEP" != "x" ]; then
   install_external_deps "$EXTERNAL_DEP" 
 fi

 if [ "x$INTERNAL_DEP" != "x" ]; then
   install_internal_deps "$INTERNAL_DEP"
 fi
 
 set_env $1 $2
 if [ "x$APPVER" != "x$CURRVER" ]; then
   write_info "Building $APPNAME $APPVER..."
   mod_main
 else
   write_info "Skipping $APPNAME $APPVER, already present"
 fi
}

# $1 - dep list
install_external_deps(){
  pkg_list=`echo $1|sed 's/\s/,/g'`
  run "dnf install $1 -y" "Install ${pkg_list} from system repo"
}

# $1 - dep list
install_internal_deps(){
  for pkg in $1; do
    go_build $pkg
  done
}



init_help(){
  addArgument "list" "list of application to be builed"
  addArgument "build" "build application"
  addArgument "app" "name of the application to build" "opt"
  addArgument "ver" "Version of the application to build" "opt"
  addArgument "noservice" "skip installation of the service" "opt"
}


export ON_HELP=init_help

case "${ARGS["default"]}" in
 list)
     go_list ${ARGS["app"]}
     ;;
 help)
     go_help
     ;;
 build)
     if [ -z ${ARGS["app"]} ]; then
       write_error "Please specify app param"
       go_help
       exit 1
     fi
     go_build ${ARGS["app"]} ${ARGS["ver"]}
     ;;
 *)
     listHelp
     ;;
esac


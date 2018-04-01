#!/bin/bash

echo "Docker Manager script v1"
echo

# Author: Yurii Reshetylo 2018
# License: MIT
#
# Example usage: ./docker-manager.sh {start|stop|restart|build|rebuild|remove} container_folder
#
# Container folder requires .docker-run file in the folder. It should contain docker run ..parameters.. and you can include other commands
#
# Optional files:
# * .docker-start  - executed after container started
# * .docker-stop   - executed after container stoped
# * .docker-remove - executed after container removed (does not delete the actual container folder)
#
# Actions:
#	start|build	starts stopped (existing) container or builds new one if does not exist
#	restart		stops and starts existing container
#	rebuild		restart action stops > removes > build new container
#	stop		stops existing container
#	remove		stops if running and removes container
#

dmstatus () {
    docker ps | grep $1
}

if [ $# -lt 2 ]; then

    echo "Not enough parameters passed"
    echo "Example usage: $0 {start|stop|restart|build|rebuild|remove} container_folder"
    echo "Available containers:"
    for container in `ls */.docker-run | awk -F"/" '{print $1}' | xargs`; do echo "$container - `dmstatus $container`";  done
    exit 1

fi

dmexit () {
    unset DM_CURRENT_DIR
    unset DM_ACTION
    unset DM_CONTAINER
    unset DM_CONTAINER_DIR
    exit 1
}

dmrunfile () {
    if [ -f "$1" ]; then
	echo "Runnning file: $1"
	source $1
    fi
}

dmstart () {
    docker start $1
    dmrunfile $START_FILE
}

dmstop () {
    docker stop $1
    dmrunfile $STOP_FILE
}

dmremove () {
    docker stop $1
    docker rm $1
    dmrunfile $REMOVE_FILE
}

dmbuild () {
    docker stop $1
    docker rm $1
    dmrunfile "$DM_CONTAINER_DIR/$DM_CONTAINER_FILE"
}

dmrestart () {
    dmstop $1
    dmstart $1
}

export DM_CURRENT_DIR=`pwd`
export DM_ACTION=$1
export DM_CONTAINER=$2
export DM_CONTAINER_DIR="$DM_CURRENT_DIR/$DM_CONTAINER"
DM_CONTAINER_FILE='.docker-run'

if [ ! -d "$DM_CONTAINER_DIR" ]; then
    echo "Directory '$DM_CONTAINER_DIR' does not exist."
    dmexit
fi

if [ ! -f "$DM_CONTAINER_DIR/$DM_CONTAINER_FILE" ]; then
    echo "Build file '$DM_CONTAINER_FILE' does not exist in '$DM_CONTAINER_DIR'"
    dmexit
fi

START_FILE="$DM_CONTAINER_DIR/.docker-start"
STOP_FILE="$DM_CONTAINER_DIR/.docker-stop"
REMOVE_FILE="$DM_CONTAINER_DIR/.docker-remove"

case "$DM_ACTION" in
    start)
        dmstart $DM_CONTAINER ;;
    build)
        dmbuild $DM_CONTAINER ;;
    stop)
        dmstop $DM_CONTAINER ;;
    restart)
        dmrestart $DM_CONTAINER ;;
    remove)
        dmremove $DM_CONTAINER ;;
    status)
        dmstatus $DM_CONTAINER ;;
    *)
        echo "Method not found" ;;
esac

dmexit
#!/bin/bash
set -e

####
#
# BUILD_NAME=yourname ./build.sh
# USE_IMAGE=no ./build.sh ## build all images (not using image in dockerhub)
# BUILD=echo ./build.sh   ## not build just making Dockerfile
#
####

CURRENT_NAME=${BUILD_NAME:-yoheikakiuchi}
BUILD_CMD=${BUILD:-docker}

### ubuntu version ###
#UBUNTU_VERSION=18.04 ## (ROS melodic) not tested
UBUNTU_VERSION=16.04  ## (ROS kinetic) recomended
#UBUNTU_VERSION=16.04_no_gl ## for not using nvidia docker2

### choreonoid version ###
#CHOREONOID_VERSION=latest ##
CHOREONOID_VERSION=release-1.6 ## recomended

###
USE_IMAGE_IN_DOCKERHUB=${USE_IMAGE:-"yes"}

DOCKER_USER=${CURRENT_NAME}
if [ ${USE_IMAGE_IN_DOCKERHUB} == "yes" ]; then
    DOCKER_USER=yoheikakiuchi
    OLD_BUILD_CMD=${BUILD_CMD}
    BUILD_CMD=echo
fi

### opengl
if [ "$UBUNTU_VERSION" == 18.04 ]; then
    ### not tested
    ${BUILD_CMD} build -f ../ros_gl/Dockerfile.ros_gl.melodic --tag=${DOCKER_USER}/ros_gl:${UBUNTU_VERSION} .
elif [ "$UBUNTU_VERSION" == "16.04_no_gl" ]; then
    ${BUILD_CMD} build -f ../ros_gl/Dockerfile.ros_no_gl --tag=${DOCKER_USER}/ros_gl:${UBUNTU_VERSION} .
else
    ${BUILD_CMD} build -f ../ros_gl/Dockerfile.ros_gl --tag=${DOCKER_USER}/ros_gl:${UBUNTU_VERSION} .
fi

### choreonoid
if [ "$CHOREONOID_VERSION" == latest ]; then
    ### todo
    sed -e "s/@UBUNTU_VERSION@/${UBUNTU_VERSION}/" -e "s/@NAME_SPACE@/${DOCKER_USER}/" \
	Dockerfile.choreonoid.latest.in > Dockerfile.choreonoid.${UBUNTU_VERSION}_${CHOREONOID_VERSION}
else
    sed -e "s/@CHOREONOID_VERSION@/${CHOREONOID_VERSION}/" -e "s/@UBUNTU_VERSION@/${UBUNTU_VERSION}/" -e "s/@NAME_SPACE@/${DOCKER_USER}/" \
        Dockerfile.choreonoid.in > Dockerfile.choreonoid.${UBUNTU_VERSION}_${CHOREONOID_VERSION}
fi
${BUILD_CMD} build -f Dockerfile.choreonoid.${UBUNTU_VERSION}_${CHOREONOID_VERSION} \
       --tag=${DOCKER_USER}/choreonoid:${UBUNTU_VERSION}_${CHOREONOID_VERSION} .

### hrpsys
sed -e "s/@CHOREONOID_VERSION@/${CHOREONOID_VERSION}/" -e "s/@UBUNTU_VERSION@/${UBUNTU_VERSION}/" -e "s/@NAME_SPACE@/${DOCKER_USER}/" \
    Dockerfile.hrpsys.in > Dockerfile.hrpsys.${UBUNTU_VERSION}_${CHOREONOID_VERSION}
${BUILD_CMD} build -f Dockerfile.hrpsys.${UBUNTU_VERSION}_${CHOREONOID_VERSION} \
       --tag=${DOCKER_USER}/hrpsys:${UBUNTU_VERSION}_${CHOREONOID_VERSION} .


if [ ${USE_IMAGE_IN_DOCKERHUB} == "yes" ]; then
    DOCKER_USER=yoheikakiuchi
    BUILD_CMD=${OLD_BUILD_CMD}
fi
### simulation environment
sed -e "s/@CHOREONOID_VERSION@/${CHOREONOID_VERSION}/" -e "s/@UBUNTU_VERSION@/${UBUNTU_VERSION}/" -e "s/@NAME_SPACE@/${DOCKER_USER}/" \
    Dockerfile.choreonoidsim.in > Dockerfile.choreonoidsim.${UBUNTU_VERSION}_${CHOREONOID_VERSION}
if [ ! -e ./rtmros_choreonoid ]; then
    git clone https://github.com/start-jsk/rtmros_choreonoid.git
fi
${BUILD_CMD} build -f Dockerfile.choreonoidsim.${UBUNTU_VERSION}_${CHOREONOID_VERSION} \
       --tag=${CURRENT_NAME}/choreonoidsim:${UBUNTU_VERSION}_${CHOREONOID_VERSION} .

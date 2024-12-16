#! /bin/bash -ex
RPI_DEB=http://raspbian.raspberrypi.com/raspbian/pool/main/libq/libqmi/libqmi_1.34.0-2.debian.tar.xz
# RPI_SRC=http://raspbian.raspberrypi.com/raspbian/pool/main/libq/libqmi/libqmi_1.34.0.orig.tar.xz
RPI_SRC=https://gitlab.freedesktop.org/mobile-broadband/libqmi.git
TAG=1.35.6-dev

# Download Raspberry Pi's debian build package
    wget -nv $RPI_DEB
    mkdir libqmi
    tar -C libqmi -Jxf ${RPI_DEB##*/}

# Download sources and run uupdate
if [[ $RPI_SRC = *.xz ]]; then
    wget -nv $RPI_SRC
    SRC_DIR=${RPI_SRC##*/}
else
    SRC_DIR=libqmi-$TAG
    git clone $RPI_SRC $SRC_DIR
    cd $SRC_DIR
    git checkout $TAG
    cd ..
fi
cd libqmi
echo "yes" | uupdate --verbose -v ${TAG%-dev} -b ../$SRC_DIR

# Build the package
cd ../libqmi-${TAG%-dev}
# disable tests
export DEB_BUILD_OPTIONS=nocheck
CMD="dpkg-buildpackage -us -uc -nc -d --target-arch armhf -a armhf --target-type armv7-unknown-linux-gnueabi"
echo $CMD
#bash -i
eval $CMD

cd ..
mkdir -p packages
mv *.deb packages
ls -ls

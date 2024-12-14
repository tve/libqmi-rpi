#! /bin/bash -ex
RPI_DEB=http://raspbian.raspberrypi.com/raspbian/pool/main/libq/libqmi/libqmi_1.34.0-2.debian.tar.xz
RPI_SRC=http://raspbian.raspberrypi.com/raspbian/pool/main/libq/libqmi/libqmi_1.34.0.orig.tar.xz

# Download Raspberry Pi's debian build package
wget -nv $RPI_DEB
mkdir libqmi
tar -C libqmi -Jxf ${RPI_DEB##*/}

# Download sources and run uupdate
wget -nv $RPI_SRC
cd libqmi
echo "yes" | uupdate --verbose -b ../${RPI_SRC##*/}

# Build the package
cd ../libqmi-1.34.0
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

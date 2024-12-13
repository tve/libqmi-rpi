#! /bin/bash -ex
cd $1
pwd

RPI_DEB=http://raspbian.raspberrypi.com/raspbian/pool/main/libq/libqmi/libqmi_1.34.0-2.debian.tar.xz
RPI_SRC=http://raspbian.raspberrypi.com/raspbian/pool/main/libq/libqmi/libqmi_1.34.0.orig.tar.xz

# We need uupdate, that pulls in a ton of crap, oh well, hope not to need to run this too many times
sudo apt-get update
sudo apt-get install -y devscripts meson bash-completion \
    gobject-introspection libgirepository1.0-dev libglib2.0-dev libgudev-1.0-dev libmbim-glib-dev \
    libqrtr-glib-dev gtk-doc-tools help2man glib-2.0 libglib2.0 libglib2.0-doc

# Fix-up stuff not properly installed by sensorgnome-dockcross
# for f in libudev.h; do
#   sudo ln -s /usr/include/$f /usr/xcc/armv7-unknown-linux-gnueabi/armv7-unknown-linux-gnueabi/sysroot/usr/include/
# done

# Download Raspberry Pi's debian build package
wget -nv $RPI_DEB
mkdir libqmi
tar -C libqmi -Jxf ${RPI_DEB##*/}

# Download sources
wget -nv $RPI_SRC

# Update the sources
cd libqmi
echo "yes" | uupdate --verbose -b ../${RPI_SRC##*/}

# Build the package
cd ../libqmi-1.34.0
# need some hacks so dpkg-buildpackage succeeds
ls /usr/xcc/armv7-unknown-linux-gnueabi/bin
( cd  /usr/xcc/armv7-unknown-linux-gnueabi/bin;
  for f in objcopy objdump strip gcc g++ ar ld pkg-config; do
    sudo ln -s armv7-unknown-linux-gnueabi-$f arm-linux-gnueabihf-$f
  done
)
# need to disable tests -- the github runner can't run the armhf executables
export DEB_BUILD_OPTIONS=nocheck
#
echo pkgconfig: $(which pkgconfig) # to double-check...
export PKG_CONFIG=/usr/bin/pkgconfig
echo dpkg-buildpackage -us -uc -nc -d --target-arch armhf -a armhf --target-type armv7-unknown-linux-gnueabi
bash -i
#
dpkg-buildpackage -us -uc -nc -d --target-arch armhf -a armhf --target-type armv7-unknown-linux-gnueabi

cp ../libqmi*.deb ../../packages

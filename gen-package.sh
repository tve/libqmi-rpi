#! /bin/bash -e

PIMOD_IMAGE=nature40/pimod:v0.6.0
OS_URL=https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2024-11-19/2024-11-19-raspios-bookworm-armhf-lite.img.xz
NAME=libqmi

OS_XZ=${OS_URL##*/}
OS_IMAGE=${OS_XZ%.xz}
TEMP_IMAGE=$NAME-temp.img
TYPE=armv7-rpi-bookworm

# Pull docker images we will need explicitly so we get an error here where the problem is obvious
# as opposed to later in the midst of something else
docker pull $PIMOD_IMAGE

if ! [[ -f /tmp/images/$TEMP_IMAGE ]]; then
    if ! [[ -f /tmp/images/$OS_IMAGE ]]; then
        ( cd /tmp;
        echo "Downloading $OS_URL";
        wget -q $OS_URL;
        xz -d $OS_XZ
        )
    fi
    echo "*** OS Image:" $(ls -h /tmp/images/$OS_IMAGE)

    echo "*** Building temp image with dependencies"
    cat >$NAME-depend.pifile <<"EOF"
    FROM /images/$IMAGE_IMG
    TO /images/$TEMP_IMG
    PUMP 1000M
    RUN apt-get update
    RUN apt-get install -y devscripts meson bash-completion gobject-introspection \
        libgirepository1.0-dev libglib2.0-dev libgudev-1.0-dev libmbim-glib-dev \
        libqrtr-glib-dev gtk-doc-tools help2man glib-2.0 libglib2.0 libglib2.0-doc
EOF
    docker run --rm --privileged \
        -v $PWD:/sg \
        -v /tmp/images:/images \
        -e PATH=/pimod:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        -e IMAGE_IMG=$OS_IMAGE \
        -e TEMP_IMG=$TEMP_IMAGE \
        -e TYPE=$TYPE \
        $PIMOD_IMAGE \
        pimod.sh /sg/$NAME-depend.pifile
    echo "*** Build temp image: $(ls /tmp/$TEMP_IMG)"
else
    echo "*** Using existing temp image"
fi

echo "*** Starting build"
date
cat >$NAME-build.pifile <<"EOF"
FROM /images/$IMG
TO /images/discard.img

WORKDIR /root
INSTALL build-$NAME.sh /root/build-$NAME.sh
RUN ./build-$NAME.sh
RUN pwd
RUN ls
EXTRACT /root/packages packages
EOF

docker run --rm --privileged \
    -v $PWD:/root \
    -v /tmp/images:/images \
    -e PATH=/pimod:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    -e NAME=$NAME \
    -e IMG=$TEMP_IMAGE \
    -e TYPE=$TYPE \
    --workdir=/root \
    $PIMOD_IMAGE \
    pimod.sh /root/$NAME-build.pifile

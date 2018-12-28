FROM debian:buster-slim AS netatalk-base
RUN  apt-get update \
 &&  apt-get install -y --no-install-recommends libgcrypt20 libdbus-1-3 libevent-2.1-6 libtdb1 dbus libacl1 libtracker-sparql-2.0-0 tracker libdbus-glib-1-2 \
 &&  rm -rf /var/lib/apt/lists/*

FROM netatalk-base AS netatalk-compiler
RUN  apt-get update
RUN  apt-get install -y curl bzip2
WORKDIR /usr/src
ARG  NETATALK_VERSION=3.1.12
ENV  NETATALK_VERSION=$NETATALK_VERSION
RUN  curl -L https://downloads.sourceforge.net/project/netatalk/netatalk/$NETATALK_VERSION/netatalk-$NETATALK_VERSION.tar.bz2 \
     | tar xj \
 &&  ln -s netatalk-$NETATALK_VERSION netatalk-current
WORKDIR /usr/src/netatalk-current
RUN  apt-get install -y gcc libc-dev make libgcrypt20-dev libdb5.3-dev libdbus-glib-1-dev libevent-dev libtdb-dev libacl1-dev libtracker-sparql-2.0-dev libtracker-miner-2.0-dev
RUN  TDB_CFLAGS="$(pkg-config --cflags tdb)" \
     TDB_LIBS="$(pkg-config --libs tdb)" \
     TRACKER_CFLAGS="$(pkg-config --cflags tracker-sparql-2.0)" \
     TRACKER_LIBS="$(pkg-config --libs tracker-sparql-2.0)" \
     ./configure --prefix=/usr \
                 --with-libevent-headers=/usr/include \
                 --with-libevent-lib=/usr/lib \
                 --localstatedir=/var \
                 --sysconfdir=/etc
RUN  make install DESTDIR=/dist
RUN  rm -rf /dist/usr/include /dist/usr/share
RUN  find /dist/usr -name '*.a'  -delete -print
RUN  find /dist/usr -name '*.la' -delete -print
RUN  find /dist -type f \
     | xargs -n1 file \
     | grep 'not stripped' \
     | awk -F": " '{print $1}' \
     | xargs -n1 -r -t strip

FROM netatalk-base AS netatalk
COPY --from=netatalk-compiler /dist /

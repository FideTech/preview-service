FROM python:3.11-bookworm
LABEL maintaner="Florian Purchess <florian@attacke.ventures>"

RUN apt-get update

RUN LIBDE265_VERSION="1.0.8" \
    && curl -L https://github.com/strukturag/libde265/releases/download/v${LIBDE265_VERSION}/libde265-${LIBDE265_VERSION}.tar.gz | tar zx \
    && cd libde265-${LIBDE265_VERSION} \
    && ./autogen.sh \
    && ./configure \
    && make -j4 \
    && make install

RUN LIBHEIF_VERSION="1.12.0" \
    && curl -L https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}/libheif-${LIBHEIF_VERSION}.tar.gz | tar zx \
    && cd libheif-${LIBHEIF_VERSION} \
    && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    && export LDFLAGS=-L/usr/local/lib \
    && export CPPFLAGS=-I/usr/local/include/libde265 \
    && ./autogen.sh \
    && ./configure \
    && make -j4 \
    && make install

RUN IMAGEMAGICK_VERSION="7.1.1-17" \
    && curl -L https://imagemagick.org/archive/ImageMagick-${IMAGEMAGICK_VERSION}.tar.gz | tar zx \
    && cd ImageMagick-${IMAGEMAGICK_VERSION} \
    && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    && export LDFLAGS=-L/usr/local/lib \
    && export CPPFLAGS=-I/usr/local/include/libheif \
    && ./configure --enable-shared --enable-static=yes --enable-symbol-prefix --with-heic --with-raw --with-gslib \
    && make -j4 \
    && make install \
    && ldconfig

RUN apt-get update && \
  apt-get install -y \
  poppler-utils qpdf libfile-mimeinfo-perl libimage-exiftool-perl ghostscript libsecret-1-0 zlib1g-dev libjpeg-dev \
  libreoffice inkscape ffmpeg xvfb \
  libnotify4 libappindicator3-1 curl \
  scribus python3-vtk9 \
  && rm -rf /var/lib/apt/lists/*

ENV DRAWIO_VERSION="12.6.5"
RUN curl -LO https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}/draw.io-amd64-${DRAWIO_VERSION}.deb && \
  dpkg -i draw.io-amd64-${DRAWIO_VERSION}.deb && \
  rm draw.io-amd64-${DRAWIO_VERSION}.deb

WORKDIR /app

RUN pip install pipenv vtk rawpy
COPY Pipfile* /app/
RUN pipenv lock
RUN pipenv install --system

COPY docker-entrypoint.sh /app/
COPY app.py /app/

RUN groupadd -r previewservice && useradd -r -s /bin/false -g previewservice previewservice
RUN chown -R previewservice:previewservice /app
USER previewservice

EXPOSE 8000

CMD ["./docker-entrypoint.sh"]

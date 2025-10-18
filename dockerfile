FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN apt update && apt install -y \
    ffmpeg \
    git \
    wget \
    unzip \
    parallel \
 && apt clean && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/lltcggie/waifu2x-caffe/releases/latest/download/waifu2x-caffe.zip \
 && unzip waifu2x-caffe.zip -d /usr/local/bin/ \
 && rm waifu2x-caffe.zip

COPY upscale-anime-smart-4k.sh /usr/local/bin/upscale-anime-smart-4k.sh
COPY upscale-anime-daemon-4k.sh /usr/local/bin/upscale-anime-daemon-4k.sh
RUN chmod +x /usr/local/bin/upscale-anime-*.sh

ENTRYPOINT ["/usr/local/bin/upscale-anime-daemon-4k.sh"]


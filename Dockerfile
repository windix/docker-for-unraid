FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SSH_USERNAME=ubuntu
ENV SSHD_CONFIG_ADDITIONAL=""
ENV TZ=Australia/Melbourne

WORKDIR /app

RUN apt update \
    && apt install -y locales openssh-server sudo vim htop aria2 curl wget unzip tmux byobu rename \
        file ffmpeg imagemagick iputils-ping netcat-openbsd net-tools software-properties-common \
        whiptail mediainfo rsync rclone \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install mono for bdinfo
RUN apt update \
    && apt install -y --no-install-recommends ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && chmod +r /usr/share/keyrings/mono-official-archive-keyring.gpg \
    && rm -rf "$GNUPGHOME" \
    && apt purge -y --auto-remove gnupg \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt update \
    && apt install -y mono-complete \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ruby
RUN apt update \
    && apt install -y git build-essential ruby-full libicu-dev zlib1g-dev imagemagick \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8

RUN mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && if ! id -u "$SSH_USERNAME" > /dev/null 2>&1; then useradd -ms /bin/bash "$SSH_USERNAME"; fi \
    && chown -R "$SSH_USERNAME":"$SSH_USERNAME" /home/"$SSH_USERNAME" \
    && chmod 755 /home/"$SSH_USERNAME" \
    && mkdir -p /home/"$SSH_USERNAME"/.ssh \
    && chown "$SSH_USERNAME":"$SSH_USERNAME" /home/"$SSH_USERNAME"/.ssh \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config

COPY files/bin/ /usr/local/bin/

RUN mkdir -p /data /mnt/user /app/ruby

RUN wget https://github.com/outlyer-net/video-contact-sheet/releases/download/1.13.4/vcs_1.13.4-pon.1_all.deb -O vcs.deb \
   && dpkg -i vcs.deb \
   && rm -f vcs.deb

RUN wget https://github.com/notofonts/noto-cjk/raw/refs/heads/main/Sans/OTC/NotoSansCJK-Regular.ttc \
    && mv NotoSansCJK-Regular.ttc /usr/share/fonts/truetype/

RUN wget https://github.com/dogbutcat/gclone/releases/download/v1.67.0-mod1.6.2/gclone-v1.67.0-mod1.6.2-linux-amd64.deb -O gclone.deb \
    && dpkg -i gclone.deb \
    && rm -f gclone.deb

RUN wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O yt-dlp \
    && chmod +x yt-dlp \
    && mv yt-dlp /usr/local/bin/

# bdinfo
RUN mkdir tmp_bdinfo \
    && cd tmp_bdinfo \
    && wget https://github.com/zoffline/BDInfoCLI-ng/raw/refs/heads/UHD_Support_CLI/prebuilt/BDInfoCLI-ng_v0.7.5.5.zip -O bdinfo-cli.zip \
    && unzip bdinfo-cli.zip \
    && mv BDInfoCLI-ng_v0.7.5.5 /app/bdinfo-cli \
    && cd .. \
    && rm -rf tmp_bdinfo

# ruby-misc scripts
# TODO split Gemfile
COPY ruby-misc/ /app/ruby/

RUN cd /app/ruby \
    && gem install bundler \
    && bundle install

EXPOSE 22

CMD ["/usr/local/bin/configure-ssh-user.sh"]

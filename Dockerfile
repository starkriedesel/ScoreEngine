FROM phusion/baseimage:0.9.16

CMD [ "/sbin/my_init" ]

# Install Prerequisites
RUN apt-get update && apt-get install -y \
  gawk sed grep tar curl gzip bzip2 bash \
  git subversion libmysqlclient-dev \
  mysql-client libvirt-dev

# Install RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN \curl -sSL https://get.rvm.io | bash -s stable --ruby=1.9.3-p484 --gems=bundler
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Clean up apt/tmp
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create application directory
RUN mkdir /app && mkdir /app/tmp && mkdir /app/log
WORKDIR /app
COPY ./Gemfile* /app/
COPY ./.ruby-* /app/

# Create ScoreEngine gemset
RUN /usr/local/rvm/bin/rvm-shell && rvm requirements
RUN bash -l -c "gem install bundler"
RUN bash -l -c "command bundle install"

# Copy source code
COPY . /app

# Precompile assets
RUN bash -l -c "command rake assets:precompile"


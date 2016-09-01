FROM ruby:2.3.0

RUN apt-get update; \ 
    curl -sL https://deb.nodesource.com/setup_6.x | bash - ;\
    apt-get install -y nodejs; \
    node -v
FROM ruby:2.3.0

RUN apt-get update; \ 
    curl -sL https://deb.nodesource.com/setup_6.x | bash - ;\
    apt-get install -y nodejs; \
    gem install rubocop; \
    git config --global --add remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*" \
    node -v
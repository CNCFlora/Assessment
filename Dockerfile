FROM cncflora/ruby

RUN gem install bundler

ADD Gemfile /opt/app/Gemfile
RUN bundle install

EXPOSE 80
CMD ["unicorn","-p","80"]

ADD . /opt/app


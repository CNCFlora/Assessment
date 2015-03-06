FROM cncflora/ruby

RUN gem install bundler

RUN mkdir /root/assessment
ADD Gemfile /root/assessment/Gemfile
RUN cd /root/assessment && bundle install

EXPOSE 80
WORKDIR /root/assessment
CMD ["unicorn","-p","80"]

ADD . /root/assessment


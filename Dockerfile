FROM cncflora/ruby

RUN gem install bundler

RUN mkdir /root/assessment
ADD Gemfile /root/assessment/Gemfile
RUN cd /root/assessment && bundle install

ADD supervisord.conf /etc/supervisor/conf.d/proxy.conf

EXPOSE 8080
EXPOSE 9001

ADD . /root/assessment


FROM cncflora/ruby

RUN gem install bundler

RUN mkdir /root/assessment
ADD Gemfile /root/assessment/Gemfile
RUN cd /root/assessment && bundle install
ADD . /root/assessment

ENV ENV production
ENV RACK_ENV production
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]


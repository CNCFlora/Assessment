ENV['RACK_ENV'] = 'test'

require 'sinatra/advanced_routes'
require_relative '../src/app'
require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'
require 'cncflora_commons'
require 'i18n'

include Rack::Test::Methods

def app
    Sinatra::Application
end

@uri = Sinatra::Application.settings.couchdb

def before_each()
end

def after_each()
    docs = http_get("#{@uri}/_all_docs")["rows"]
    docs.each{ |e|
        deleted = http_delete( "#{@uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
    }
    sleep 1
end

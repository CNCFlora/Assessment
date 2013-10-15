require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?
require 'multi_json'

config_file 'config.yml'
enable :sessions

def view(page,data)
    @config = Sinatra::Application.settings;
    @strings = MultiJson.load(File.read("locales/#{@config.lang}.json"),:symbolize_keys => true)
    @config_hash = {:connect => @config.connect, :lang => @config.lang, :couchdb => @config.couchdb}
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || '{}'}
    mustache page, {}, {:strings => @strings}.merge(@config_hash).merge(@session_hash).merge(data)
end

get '/' do
    view :index, {:foo =>"bar"}
end

post '/login' do
    session[:logged] = true
    session[:user] = MultiJson.load params[:user]
    204
end

post '/logout' do
    session[:logged] = false
    session[:user] = false
    204
end
    

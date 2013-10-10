require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?
require 'multi_json'

config_file 'config.yml'

def view(page,data)
    @config = Sinatra::Application.settings;
    @strings = MultiJson.load(File.read("locales/#{@config.lang}.json"),:symbolize_keys => true)
    mustache page, {}, {:strings => @strings}.merge(data)
end

get '/' do
    view :index, {:foo =>"bar"}
end


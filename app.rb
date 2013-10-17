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
    if session[:logged] 
        session[:user]['roles'].each do | role  |
            @session_hash[ "role-#{role['role'].downcase}" ] = true
        end
    end
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
    
get "/families" do
    families = ["ACANTHACEAE","RUBIACEAE"]
    view :families, {:families => families}
end

get "/family/:family" do
    species = [ {:scientificName => "name", :have => false, :scientificNameAuthorship => "L.", :_id => "123"},
                {:scientificName => "other name", :have => true, :scientificNameAuthorship => "B.", :_id => "321"}]
    view :species, {:species => species , :family => params[:family]}
end

get "/search" do
    view :index,{}
end

get "/workflow" do
    families = ["ACANTHACEAE","RUBIACEAE"]
    view :workflow, {:families => families}
end

get "/workflow/:family/:status" do
    list = [ {:taxon => {:scientificName => "name", :scientificNameAuthorship => "L."}, :_id => "123" },
             {:taxon => {:scientificName => "other name", :scientificNameAuthorship => "B."}, :_id => "321"}]
    content_type :json
    MultiJson.dump list
end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?

require 'cncflora_commons'
require 'couchdb_basic'

if development? then
    also_reload "routes/*"
end

if test? then
    set :test , true
else
    set :test , false
end

setup '../config.yml'

def require_logged_in
    redirect("#{settings.base}/") unless is_authenticated?
end
 
def is_authenticated?
    return !!session[:logged]
end


set :conn, Couchdb.new( settings.couchdb )

Dir["src/routes/*.rb"].each {|file|
    require_relative file.gsub('src/','')
}

def view(page,data)
    @config = settings.config
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || {}, :user_json => session[:user].to_json }
    if session[:logged] 
        session[:user]['roles'].each do | role |
            @session_hash["role-#{role['role'].downcase}"] = true
        end
    end
    @session_hash["role-assessor"] = true
    @session_hash["role-evaluator"] = true
    mustache page, {}, @config.merge(@session_hash).merge(data)
end

get '/' do
    view :index,{}
end

post '/login' do
    session[:logged] = true
    preuser =  JSON.parse(params[:user])
    if settings.test then
        session[:user] = preuser
    else
        user = http_get("#{settings.connect}/api/token?token=#{preuser["token"]}")
        session[:user] = user
    end
    204
end

post '/logout' do
    session[:logged] = false
    session[:user] = false
    204
end


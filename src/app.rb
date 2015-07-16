Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?

require 'securerandom'

require_relative 'commons'

if development? then
    also_reload "routes/*"
end

if test? then
    set :test , true
else
    set :test , false
end

setup 'config.yml'

def require_logged_in
    redirect("#{settings.base}/?back_to=#{request.path_info}") unless is_authenticated?
end
 
def is_authenticated?
    return !!session[:logged]
end

Dir["src/routes/*.rb"].each {|file|
    require_relative file.gsub('src/','')
}

def view(page,data)
    @config = settings.config
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || {}, :user_json => session[:user].to_json }
    if data[:db]
      data[:db_name] = data[:db].gsub('_',' ').upcase
    end
    if session[:logged] 
      if data[:db] 
        session[:user]['roles'].each do | role |
          if role['context'] == data[:db]
            role['roles'].each do | role |
              @session_hash["role-#{role['role'].downcase}"] = true
            end
          end
        end
      end
    end
    #@session_hash["role-assessor"] = true
    #@session_hash["role-evaluator"] = true
    mustache page, {}, @config.merge(@session_hash).merge(data)
end

get '/' do
  if session[:logged] && params[:back_to] then
    redirect "#{settings.base}#{ params[:back_to] }"
  elsif session[:logged] then
    dbs=[]
    all=http_get("#{ settings.couchdb }/_all_dbs")
    all.each {|db|
      if db[0] != "_" && !db.match('_history') then
        dbs << {:name=>db.gsub("_"," ").upcase,:db =>db}
      end
    }
    view :index,{:dbs=>dbs}
  else
    view :index,{:dbs=>[]}
  end
end

post '/login' do
    session[:logged] = true
    preuser =  JSON.parse(params[:user])
    if settings.test then
        session[:user] = preuser
    else
        user = http_get("#{settings.connect}/api/token?token=#{preuser["token"]}")
        if user["email"] == preuser["email"] then
          session[:user] = preuser
        end
    end
    204
end

post '/logout' do
    session[:logged] = false
    session[:user] = false
    204
end
  

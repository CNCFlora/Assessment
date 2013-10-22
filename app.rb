require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?
require 'multi_json'
require_relative 'model/couchdb'

config_file 'config.yml'
enable :sessions

def getDb(user,password,dbname)
    url = "http://#{user}:#{password}@localhost:5984/#{dbname}"
    CouchDB.new url
end

db = getDb("bruno","Lam5pada","test_rb")

def setMetadata(status='open')
    metadata = Metadata.new.shema    
    metadata[:contributor] = session[:user][:name]
    metadata[:contact] = session[:user][:email]
    metadata[:modified] = Time.now.to_i
    metadata[:status] = status
    metadata
end


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
    session[:user] = MultiJson.load(params[:user],:symbolize_keys => true)
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

get "/assessments/:id" do
    content_type :json
    db.get(params[:id]).to_json
end

post "/assessments" do    
    params[:metadata][:creator] = session[:user][:name]
    params[:metadata][:contributor] = session[:user][:name]
    params[:metadata][:contact] = session[:user][:email]
    assessment = db.create( params )
    [201, "/assessments/#{assessment[:_id]}"]    
end

put "/assessments/:id" do    
    assessment = db.get(params[:id])
    assessment[:metadata][:contributor] = session[:user][:name]
    assessment[:metadata][:contact] = session[:user][:email]
    assessment[:metadata][:modified] = Time.now.to_i
    params[:metadata] = assessment[:metadata]
    params[:taxon] = assessment[:taxon]
    params[:profile] = assessment[:profile]
    assessment.each{ |key, value|
        assessment[key] = params[key]        
    }
    db.update(assessment)
    204
end

put "/assessments/:id/status/:status" do
    assessment = db.get(params[:id])
    assessment[:metadata][:contributor] = session[:user][:name]
    assessment[:metadata][:contact] = session[:user][:email]
    assessment[:metadata][:modified] = Time.now.to_i
    assessment[:metadata][:status] = params[:status]
    params[:metadata] = assessment[:metadata]
    params[:taxon] = assessment[:taxon]
    params[:profile] = assessment[:profile]
    assessment.each{|key,value|
        assessment[key] = params[key]        
    }
    db.update(assessment)
    204
    # Como retornar
end

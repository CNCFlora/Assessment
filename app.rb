require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development? || test?
require 'multi_json'
require 'time'
require_relative 'model/couchdb'
require_relative 'model/assessment'

config_file 'config.yml'
enable :sessions

if development? || test? 
    also_reload "model/*.rb"
end

db = CouchDB.new Sinatra::Application.settings.couchdb

allows = []
File.foreach("config/checklist.csv") do |csv_line|
    r = /"([\w]*)";"([\w]*)";"([a-zA-Z-]*)";"([\w\.-]*)";"([\w\.-]*)"/
    csv_row = r.match csv_line
    allows.push csv_row[1]
    allows.push [csv_row[2],csv_row[3],csv_row[4],csv_row[5]].join(' ')
end
allows = allows.uniq.map { | name | name.strip }

def view(page,data)
    @config = Sinatra::Application.settings;
    @strings = MultiJson.load(File.read("locales/#{@config.lang}.json"),:symbolize_keys => true)
    @config_hash = {:connect => @config.connect, :lang => @config.lang, :couchdb => @config.couchdb}
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || '{}'}
    if session[:logged] 
        session[:user][:roles].each do | role |
            @session_hash["role-#{role[:role].downcase}"] = true
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

get "/search" do
    view :index,{}
end
    
get "/families" do
    docs = db.view('taxonomy','species_by_family',{:reduce=>true,:group=>true})
    families = docs.map { | doc | doc[:key ] } 
                   .select { | family | allows.include? family }
    view :families, {:families => families}
end

get "/family/:family" do
    assessments = db.view('assessments','by_family',{:key => params[:family], :reduce => false})
                    .map { | doc | doc[:value][:taxon][:scientificName] }
    docs = db.view('taxonomy','species_by_family', {:key => params[:family],:reduce => false})
    species = docs.map { | doc | doc[:value] } 
                  .select { | spp | allows.include? spp[:scientificName] }
                  .map { | doc | doc[:have] = assessments.include? doc[:scientificName]; doc}
    view :species, {:species => species , :family => params[:family]}
end

get "/specie/:lsid" do
    spp = db.get(params[:lsid])
    assessments = db.view('assessments','by_taxon_lsid',{:key=>params[:lsid],:reduce=>false})
    if assessments.length >= 1
        redirect to("/assessment/#{assessments.last[:id]}")
    else
        view :new, {:specie => spp}
    end
end

post "/assessment" do    
    spp = db.get(params[:lsid])    
    profile = db.view('species_profiles','by_taxon_lsid',{:key => params[:lsid],:reduce=>false}).last[:id]

    assessment = Assessment.new.schema

    assessment[:profile] = profile
    assessment[:dateOfAssessment] = Time.new.to_i
    assessment[:assessor] = session[:user][:name]

    assessment[:taxon][:lsid] = spp[:_id]
    assessment[:taxon][:family] = spp[:family]
    assessment[:taxon][:scientificName] = spp[:scientificName]
    assessment[:taxon][:scientificNameAuthorship] = spp[:scientificNameAuthorship]

    assessment[:metadata][:creator] = session[:user][:name]
    assessment[:metadata][:contributor] = session[:user][:name]
    assessment[:metadata][:contact] = session[:user][:email]
    assessment[:metadata][:description] = "Assessment for #{spp[:scientificName]}"
    assessment[:metadata][:title] = "Assessment for #{spp[:scientificName]}"
    assessment[:metadata][:modified] = Time.now.to_i
    assessment[:metadata][:created] = Time.now.to_i

    assessment = db.create(assessment)

    redirect to("/assessment/#{assessment[:_id]}")
end

get "/assessment/:id" do
    assessment = db.get(params[:id])
    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    schema = MultiJson.load(db.get("_design/assessments")[:schema][:assessment][27..-4], :symbolize_keys=>true)
    schema[:properties].delete(:metadata)
    schema[:properties].delete(:taxon)
    schema[:properties].delete(:profile)
    schema[:properties].delete(:dateOfAssessment)
    schema[:properties].delete(:review)
    schema[:properties].delete(:comments)

    view :edit, {:assessment => assessment,:schema=>schema.to_json,:data => assessment.to_json}
end

post "/assessment/:id" do    
    assessment = db.get(params[:id])
    contributors = assessment[:metadata][:contributor].split(" ; ")
    contributors = [session[:user][:name]].concat(contributors).uniq()
    assessment[:metadata][:contributor] = contributors.join(" ; ")
    contacts = assessment[:metadata][:contact].split(" ; ")
    contacts = [session[:user][:email]].concat(contributors).uniq()
    assessment[:metadata][:contact] = contributors.join(" ; ")

    assessment[:metadata][:modified] = Time.now.to_i

    data  = MultiJson.load(params[:data], :symbolize_keys=>true)
    data.each{ |key, value|
        assessment[key] = value
    }

    db.update(assessment)

    content_type :json
    assessment.to_json
end

post "/assessment/:id/status/:status" do    
    assessment = db.get(params[:id])
    contributors = assessment[:metadata][:contributor].split(" ; ")
    contributors = [session[:user][:name]].concat(contributors).uniq()
    assessment[:metadata][:contributor] = contributors.join(" ; ")
    contacts = assessment[:metadata][:contact].split(" ; ")
    contacts = [session[:user][:email]].concat(contributors).uniq()
    assessment[:metadata][:contact] = contributors.join(" ; ")
    assessment[:metadata][:status] = params[:status]
    assessment[:metadata][:modified] = Time.now.to_i

    db.update(assessment)
    redirect to("/assessment/#{assessment[:_id]}")
end

get "/workflow" do
    families = ["ACANTHACEAE","RUBIACEAE"]
    view :workflow, {:families => families}
end

get "/workflow/:family/:status" do
    list = [ {:taxon => {:scientificName => "name", :scientificNameAuthorship => "L."}, :_id => "123" },
             {:taxon => {:scientificName => "other name", :scientificNameAuthorship => "B."}, :_id => "321"}]
    #list = db.view('assessments','by_family_and_status',{:reduce=>false,:key=>["ACANTHAC","open"]})
    content_type :json
    MultiJson.dump list
end


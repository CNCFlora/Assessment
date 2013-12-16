require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development? || test?
require 'multi_json'
require 'time'
require 'uri-handler'
require 'rest-client'
require_relative 'model/couchdb'
require_relative 'model/assessment'

config_file ENV['config'] || 'config.yml'
use Rack::Session::Pool
set :session_secret, '1flora2'

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
    @config_hash = {:connect => @config.connect, :lang => @config.lang, :couchdb => @config.couchdb, :base => @config.base, :profiles=>@config.profiles,:biblio=>@config.biblio}
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || '{}'}
    if session[:logged] 
        session[:user][:roles].each do | role |
            @session_hash["role-#{role[:role].downcase}"] = true
        end
    end
    mustache page, {}, {:strings => @strings}.merge(@config_hash).merge(@session_hash).merge(data)
end

get '/' do
    view :index,{}
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
    uri =  "#{settings.es}/assessment/_search?q=#{params[:query].to_uri}"
    r = RestClient.get uri
    res = MultiJson.load(r.to_str,:symbolize_keys => true)[:hits][:hits].map { |hit| hit[:_source]}
    view :index,{:result=>res,:query=>params[:query]}
end

get "/biblio" do
    uri =  "#{settings.es}/biblio/_search?q=#{params[:term].to_uri}"
    r = RestClient.get uri
    res = MultiJson.load(r.to_str,:symbolize_keys => true)[:hits][:hits]
                   .map { |hit| {:label=>hit[:_source][:fullCitation],:value=>hit[:_source][:_id]}}
    MultiJson.dump res
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

    if assessment[:review] && assessment[:review][:rationale].length >=1 
        assessment[:rationale] = assessment[:review][:rationale]
    end

    assessment["status-#{assessment[:metadata][:status]}"] = true
    view :view, {:assessment => assessment}
end

get "/assessment/:id/edit" do
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

    data = MultiJson.load(params[:data], :symbolize_keys=>true)
    data[:_rev] = assessment[:_rev]
    data[:_id] = assessment[:_id]
    data[:metadata] = assessment[:metadata]
    data[:taxon] = assessment[:taxon]
    data[:profile] = assessment[:profile]

    if assessment[:review]
        data[:review] = assessment[:review]
    end
    if assessment[:comments]
        data[:comments] = assessment[:comments]
    end

    db.update(data)

    content_type :json
    data.to_json
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

get "/assessment/:id/review" do 
    assessment = db.get(params[:id])
    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    if assessment[:review] && assessment[:review][:status] 
        assessment[:review]["status-#{assessment[:review][:status]}"] = true
    end

    if assessment[:review] && assessment[:review][:rationale].length >=1 
        assessment[:rationale] = assessment[:review][:rationale]
    end

    view :review, {:assessment => assessment}
end

post "/assessment/:id/review" do
    assessment = db.get(params[:id])

    assessment[:review] = {:status=>params[:status],:comment=>params[:comment],:rationale=>params[:rationale]}
    assessment[:evaluator] = session[:user][:name]

    contributors = assessment[:metadata][:contributor].split(" ; ")
    contributors = [session[:user][:name]].concat(contributors).uniq()
    assessment[:metadata][:contributor] = contributors.join(" ; ")
    contacts = assessment[:metadata][:contact].split(" ; ")
    contacts = [session[:user][:email]].concat(contributors).uniq()
    assessment[:metadata][:contact] = contributors.join(" ; ")

    db.update(assessment)
    redirect to("/assessment/#{assessment[:_id]}")
end

get "/assessment/:id/comment" do
    assessment = db.get(params[:id])
    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    if assessment[:review] && assessment[:review][:rationale].length >=1 
        assessment[:rationale] = assessment[:review][:rationale]
    end

    owner = assessment[:metadata][:creator] == session[:user][:name]
    view :comments, {:assessment => assessment,:owner=>owner }
end

post "/assessment/:id/comment" do
    assessment = db.get(params[:id])

    if assessment[:comments] == nil 
        assessment[:comments] = []
    end

    assessment[:comments].push({:creator=>session[:user][:name] ,:contact=>session[:user][:email] ,:created=>Time.new.to_i ,:comment=>params[:comment]})

    db.update(assessment)
    redirect to("/assessment/#{assessment[:_id]}")
end

get "/workflow" do
    families = []
    session[:user][:roles].each { | role |
        role[:entities].each { | entity |
            if entity[:name] == entity[:name].upcase
                families.push(entity[:name])
            end
        }
    }
    families = families.sort
    view :workflow, {:families => families.uniq}
end

get "/control" do


    docs_assessment = db.view('assessments','by_taxon_lsid',{:reduce=>false})
    docs_profile = db.view('species_profiles','by_taxon_lsid',{:reduce=>false})


    status = {
                :not_open=>{ :status=>"not_open",:families=>[] },
                :open=>{ :status=>"open",:families=>[] },
                :review=>{ :status=>"review",:families=>[] },
                :comments=>{ :status=>"comments",:families=>[] },
                :published=>{ :status=>"published",:families=>[] }
            }

    lsid = []
    family = {}
    docs_assessment.each do |assessment|
        if allows.include? assessment[:value][:taxon][:scientificName]
            if !status[ assessment[:value][:metadata][:status].to_sym ][:families].find{ |f| f[:name] == assessment[:value][:taxon][:family] }
                family = { :name=>assessment[:value][:taxon][:family],:species=>[],:count=>0,:total=>0 }
                status[ assessment[:value][:metadata][:status].to_sym ][:families].push( family )
            end
            specie = { :lsid=>assessment[:value][:taxon][:lsid], :scientificName=>assessment[:value][:taxon][:scientificName] }
            f = status[ assessment[:value][:metadata][:status].to_sym ][:families].find{ |f| f[:name] == assessment[:value][:taxon][:family] }
            if f
                f[:species].push(specie)
                f[:count] = f[:count] + 1
            end
            lsid.push( assessment[:value][:taxon][:lsid] )
        end
    end    

    docs_profile.each do |profile|
        if allows.include? profile[:value][:taxon][:scientificName]
            if !lsid.include? profile[:value][:taxon][:lsid]
                if !status[ :not_open ][:families].find{ |f| f[:name] == profile[:value][:taxon][:family] }
                    family = { :name=>profile[:value][:taxon][:family],:species=>[],:count=>0,:total=>0 }
                    status[ :not_open ][:families].push( family )
                end    
                specie = { :lsid=>profile[:value][:taxon][:lsid], :scientificName=>profile[:value][:taxon][:scientificName] }
                f = status[ :not_open ][:families].find{ |f| f[:name] == profile[:value][:taxon][:family] }
                if f
                    f[:species].push(specie)
                    f[:count] = f[:count] + 1
                end
            end            
        end
    end

    families = {}
    docs_profile.each do |profile|
        if allows.include? profile[:value][:taxon][:scientificName]
            if !families.keys.include? profile[:value][:taxon][:family]
                families[ profile[:value][:taxon][:family] ] = 0
            end
            families[ profile[:value][:taxon][:family] ] = families[ profile[:value][:taxon][:family] ] + 1
        end
    end

    families.each do |key,value|
        not_open = status[:not_open][:families].find{ |f| f[:name] == key }
        if not_open
            not_open[:total] = value
        end
        open = status[:open][:families].find{ |f| f[:name] == key }
        if open
            open[:total] = value        
        end
        review = status[:review][:families].find{ |f| f[:name] == key }
        if review
            review[:total] = value
        end
        comments = status[:comments][:families].find{ |f| f[:name] == key }
        if comments
            comments[:total] = value
        end
        published = status[:published][:families].find{ |f| f[:name] == key }
        if published
            published[:total] = value
        end
    end


    sorted = status[:not_open][:families].sort { |family1,family2| family1[:name] <=> family2[:name] }    
    status[:not_open][:families] = sorted

    view :control, {:status => status.values}


end


get "/workflow/:family/:status" do
    data = []
    
    if params[:status] == "empty"
        lsid_assessments = []
        list = db.view( 'assessments','by_family',{ :reduce=>false,:key=>params[:family] } )
        list.each do |item|
            lsid_assessments.push( item[:value][:taxon][:lsid] )
        end

        profiles = db.view( 'species_profiles','by_family',{ :reduce=>false,:key=>params[:family] } )

        profiles.each do |profile|
            if !lsid_assessments.include? profile[:value][:taxon][:lsid]
                data.push( profile[:value] )
            end
        end
    else
        list = db.view( 'assessments','by_family_and_status',{ :reduce=>false,:key=>[params[:family],params[:status]] } ) 
        list.each { | row | data.push row[:value] } 
    end

    data = data.sort { |specie1,specie2| specie1[:taxon][:scientificName] <=> specie2[:taxon][:scientificName] }
    content_type :json
    MultiJson.dump data
end


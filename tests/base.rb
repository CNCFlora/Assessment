ENV['RACK_ENV'] = 'test'

require_relative '../src/app'

require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'

include Rack::Test::Methods

def app
    Sinatra::Application
end

RSpec.configure do |config|
  config.include RSpecHtmlMatchers
end

# wait for elasticsearch
sleep 5

def before_each()
    uri = "#{Sinatra::Application.settings.couchdb}/cncflora_test"
    uri2 = "#{ Sinatra::Application.settings.elasticsearch }/cncflora_test"
    http_put(uri, {})
    http_put(uri2, {})

    docs = http_get("#{uri}/_all_docs?include_docs=true")["rows"]
    docs.each{ |e|
      deleted = http_delete( "#{uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
      r=http_delete("#{uri2}/#{e["doc"]["metadata"]["type"]}/#{e["id"]}")
    }

    data = [
      {"metadata"=> { "type"=>"taxon", "identifier"=>"taxon1" },
                     "_id" => "taxon1", 
                     "family"=> "ACANTHACEAE", 
                     "scientificName"=>"Justicia clivalis S.Profice",
                     "scientificNameWithoutAuthorship"=>"Justicia clivalis",
                     "scientificNameAuthorship"=>"S.Profice",
                     "taxonRank"=>"species", 
                     "taxonomicStatus"=>"accepted" },
      {"metadata"=> { "type"=>"taxon", "identifier"=>"taxon2" },
                     "_id" => "taxon2", 
                     "family"=> "ACANTHACEAE", 
                     "scientificName"=>"Aphelandra longiflora S.Profice",
                     "scientificNameWithoutAuthorship"=>"Aphelandra longiflora",
                     "scientificNameAuthorship"=>"S.Profice",
                     "taxonRank"=>"species", 
                     "taxonomicStatus"=>"accepted" },
      {"metadata"=> { "type"=>"taxon", "identifier"=>"taxon3" },
                     "_id" => "taxon3", 
                     "family"=> "ACANTHACEAE", 
                     "scientificName"=>"Aphelandra longiflora2 S.Profice",
                     "scientificNameWithoutAuthorship"=>"Aphelandra longiflora2",
                     "scientificNameAuthorship"=>"S.Profice",
                     "acceptedNameUsage"=> "Aphelandra longiflora",
                     "taxonRank"=>"species", 
                     "taxonomicStatus"=>"synonym" },
      {"metadata"=> { "type"=>"taxon", "identifier"=>"taxon4" },
                     "_id" => "taxon4", 
                     "family"=> "BROMELIACEAE", 
                     "scientificName"=>"Uma bromelia Forzza",
                     "scientificNameWithoutAuthorship"=>"Uma bromelia",
                     "scientificNameAuthorship"=>"Forzza",
                     "taxonRank"=>"species", 
                     "taxonomicStatus"=>"accepted" },
      {"metadata"=> {"contributor"=>"foo","modified"=> 1386183680, "created"=>1386183678,"identifier"=>"assess1",
                    "contact"=>"foo", "creator"=>"foo", "type"=>"assessment", "status"=>"open"}, 
                    "_id"=>"assess1", "assessor"=>"foo", "evaluator"=>"bar", "category"=>"EN",
                    "criteria"=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
                    "taxon"=>{"lsid"=>"1", "family"=>"ACANTHACEAE", 
                             "scientificNameWithoutAuthorship"=>"Aphelandra longiflora",
                             "scientificName"=>"Aphelandra longiflora S.Profice"} }
    ]

    r=http_post("#{uri}/_bulk_docs",{:docs=>data})
    r=index_bulk("cncflora_test",data)
end

def after_each()
    uri = "#{Sinatra::Application.settings.couchdb}/cncflora_test"
    uri2 = "#{ Sinatra::Application.settings.elasticsearch }/cncflora_test"
    http_delete(uri)
    http_delete(uri2)
end


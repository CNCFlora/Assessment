ENV['RACK_ENV'] = 'test'

require_relative '../src/app'

require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'
require 'cncflora_commons'

include Rack::Test::Methods

def app
    Sinatra::Application
end

def before_each()
    uri = "#{Sinatra::Application.settings.datahub}/cncflora_test"
    docs = http_get("#{uri}/_all_docs")["rows"]
    docs.each{ |e|
      deleted = http_delete( "#{uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
    }
    sleep 1

      http_post(uri,{:metadata=> { :type=>"taxon", :identifier=>"taxon1" },
                     :_id => "taxon1", 
                     :family=> "ACANTHACEAE", 
                     :scientificName=>"Justicia clivalis S.Profice",
                     :scientificNameWithoutAuthorship=>"Justicia clivalis",
                     :scientificNameAuthorship=>"S.Profice",
                     :taxonRank=>"species", 
                     :taxonomicStatus=>"accepted" })

      http_post(uri,{:metadata=> { :type=>"taxon", :identifier=>"taxon2" },
                     :_id => "taxon2", 
                     :family=> "ACANTHACEAE", 
                     :scientificName=>"Aphelandra longiflora S.Profice",
                     :scientificNameWithoutAuthorship=>"Aphelandra longiflora",
                     :scientificNameAuthorship=>"S.Profice",
                     :taxonRank=>"species", 
                     :taxonomicStatus=>"accepted" })

      http_post(uri,{:metadata=> { :type=>"taxon", :identifier=>"taxon3" },
                     :_id => "taxon3", 
                     :family=> "ACANTHACEAE", 
                     :scientificName=>"Aphelandra longiflora2 S.Profice",
                     :scientificNameWithoutAuthorship=>"Aphelandra longiflora2",
                     :scientificNameAuthorship=>"S.Profice",
                     :acceptedNameUsage=> "Aphelandra longiflora",
                     :taxonRank=>"species", 
                     :taxonomicStatus=>"synonym" })

      http_post(uri,{:metadata=> { :type=>"taxon", :identifier=>"taxon4" },
                     :_id => "taxon4", 
                     :family=> "BROMELIACEAE", 
                     :scientificName=>"Uma bromelia Forzza",
                     :scientificNameWithoutAuthorship=>"Uma bromelia",
                     :scientificNameAuthorship=>"Forzza",
                     :taxonRank=>"species", 
                     :taxonomicStatus=>"accepted" })

      http_post(uri,{
          :assessor=>"foo", :evaluator=>"bar", :category=>"EN", :criteria=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
          :metadata=>{:contributor=>"foo",:modified=> 1386183680, :created=>1386183678,:contact=>"foo", :creator=>"foo", :type=>"assessment", :status=>"open"}, 
          :taxon=>{:lsid=>"1", :family=>"ACANTHACEAE", :scientificNameWithoutAuthorship=>"Aphelandra longiflora",:scientificName=>"Aphelandra longiflora S.Profice"}
      })

      sleep 2
end

def after_each()
end


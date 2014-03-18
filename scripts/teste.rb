# encoding: utf-8
require_relative '../model/assessment'
require_relative '../model/couchdb'
require 'multi_json'
require 'yaml'

thing = YAML.load_file('../config.yml')
puts thing.inspect


db = CouchDB.new("http://tester:tester@localhost:5984/cncflora")
# db = CouchDB.new("http://admin:couchdb_at_jbrj@cncflora.jbrj.gov.br:5984/cncflora")
species = db.view('species_profiles','by_taxon_lsid')

count = 0
vet = []


species.each do |item|
        
    doc = item[:value]    


    if doc[:threats] != nil
        # puts "familia = #{doc[:taxon] [:family]} - espécie = #{doc[:taxon] [:scientificName]} - ameaças = #{doc[:threats]}"
    end
       
#     if !doc[:reproduction].nil? && ( !doc[:reproduction][:sexualSystem].nil? || !doc[:reproduction][:system].nil? )
        
#         count = count + 1
        
#         sexual = doc[:reproduction][:sexualSystem]
#         reproduction = doc[:reproduction][:system]

#         doc[:reproduction][:sexualSystem] = reproduction
#         doc[:reproduction][:system] = sexual

#         vet.push( doc )

#         if doc[:reproduction][:sexualSystem].nil?
#             doc[:reproduction].delete(:sexualSystem)
#         end

#         if doc[:reproduction][:system].nil?
#             doc[:reproduction].delete(:system)
#         end
        
#         db.update(doc)
#         puts "#{doc[:taxon][:family]} - #{doc[:taxon][:scientificName]}"
#     end
end

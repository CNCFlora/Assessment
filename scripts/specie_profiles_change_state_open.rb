# encoding: utf-8
require_relative '../model/assessment'
require_relative '../model/couchdb'


db = CouchDB.new("http://admin:couchdb_at_jbrj@146.134.16.15:5984/cncflora")
species = db.view('species_profiles','by_family')

families = {}
families["APOCYNACEAE"] = 0
families["APODANTHACEAE"] = 0
families["AQUIFOLIACEAE"] = 0
families["BURSERACEAE"] = 0
families["CACTACEAE"] = 0
families["CALOPHYLLACEAE"] = 0
families["CARYOPHYLLACEAE"] = 0
families["CELASTRACEAE"] = 0
families["CONNARACEAE"] = 0
families["CONVOLVULACEAE"] = 0
families["GENTIANACEAE"] = 0
families["LORANTHACEAE"] = 0
families["MORACEAE"] = 0
families["OCHNACEAE"] = 0
families["POACEAE"] = 0
families["SANTALACEAE"] = 0
families["SCROPHULARIACEAE"] = 0


count = 0
species.each do |item|

    doc = item[:value]    
    if families.keys.include? doc[:taxon][:family]
        doc[:metadata][:status] = "open"
        families[ doc[:taxon][:family] ] = families[ doc[:taxon][:family] ] + 1
        # db.update(doc)
    end

end

families.each do |key,value|
    puts "#{key}=#{value}"
end


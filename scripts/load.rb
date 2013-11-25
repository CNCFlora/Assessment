# encoding: utf-8
require_relative '../model/assessment'
require_relative '../model/couchdb'


db = CouchDB.new("http://localhost:5984/cncflora")

count = 1
taxons = {}
profiles = {}
assessments = {}
File.open('checklist.csv', 'r') do |file|  
	while line = file.gets  
    actualrow = line.gsub("\"","").split(";")
    taxon_id = "taxon#{count}"
    profile_id = "profile#{count}"
    taxon = {:metadata=>{:type=>"taxon",:contributor=>"test",:created=>0,:valid=>true,:identifier=>taxon_id},
      :_id => taxon_id, :taxonID => taxon_id,
      :kingdom=> "", :order=> "", :phylum=> "", :class=> "",
      :family=> actualrow[0], :genus=>actualrow[1],
      :scientificName=>"#{actualrow[1]} #{actualrow[2]}",
      :scientificNameAuthorship=>"S.Profice",
      :taxonRank=>"species", :taxonomicStatus=>"accepted"}

    db.create(taxon)

		profile = {:metadata=>{:type=>"profile",:contributor=>"test",:created=>0,:valid=>true,:identifier=>profile_id},
      :taxon=>{:family=>taxon[:family],:scientificName=>taxon[:scientificName],:scientificNameAuthorship=>taxon[:scientificNameAuthorship],:lsid=>taxon_id},
      :ecology=>{:lifeForm=>""},
      :_id=> profile_id}

    db.create(profile)
		
    count += 1

	end
end
class Taxon
    def initialize
    	@schema = {
    		:taxonID => '',
			:kingdom => '',
			:phylum => '',
			:class => '',
			:order => '',
			:family => '',
			:genus => '',
			:specificEpithet => '',
			:infraspecificEpithet => '',
			:taxonRank => '', #enum:["kingdom","phylum","class","order","family","genus","species","subspecies","variety"]},
			:scientificName => '',
			:scientificNameAuthorship => '',
			:taxonomicStatus => '', #enum: ["accepted","synonym","misapplied","proParteSynonym","homotypicSynonym","heterotypicSynonym"]},
			:nomenclaturalStatus => '',
			:acceptedNameUsage => '',
			:acceptedNameUsageID => '',
			:fbid => '',
    	}
    end

    def schema
    	@schema
    end

end

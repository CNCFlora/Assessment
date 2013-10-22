class Taxon
    def initialize
    	@schema = {
            :lsid => '',
			:family => '',
			:scientificName => '',
			:scientificNameAuthorship => ''
    	}
    end

    def schema
    	@schema
    end

end

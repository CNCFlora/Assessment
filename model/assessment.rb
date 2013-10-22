require_relative 'metadata'
require_relative 'taxon'
# require_relative 'change'
# require_relative 'information'

class Assessment    

    def initialize()
    	@schema = {    		
    		:metadata => Metadata.new.schema,
    		:taxon => Taxon.new.schema,
    		:profile => '',
    		:assessor => '',
			:evaluator => '',
			:category => '',			
			:criteria => '',
            :rationale => '',
            :dateOfAssessment => Time.now.to_i,
            # :change => Change.new.schema,
            # :information => Information.new.schema,
            :notes => ''           
    	}
    end

    def schema
    	@schema
    end

end
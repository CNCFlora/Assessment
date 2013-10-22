class Metadata

	def initialize
		@schema = {
			:bibliographicCitation => "",
			:contributor => "",
			:contact => "",
			:created => Time.now.to_i,
			:creator => "",
			:description => "",
			:identifier => "",
			:type => "",
			:modified => 0,
			:language => "",
			:source => "",
			:subject => "",
			:title => "",
			:valid => true,
			:status => 'open'
		}
	end

	
	def schema
		@schema
	end

end
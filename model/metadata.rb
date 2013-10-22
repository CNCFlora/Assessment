
class Metadata

	def initialize()
		@schema = {
			:bibliographicCitation => "",
			:contributor => "",
			:contact => "",
			:created => Time.now.to_i,
			:creator => "",
			:description => "",
			:identifier => "",
			:type => "assessment",
			:modified => Time.now.to_i,
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


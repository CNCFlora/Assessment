
class Information

	def initialize()
		@schema = {
			:currentPopulationTrend => '',
			:dateLastSeen => '',
			:generationLength => '',
			:numberOfLocations => 0,
			:numberOfMatureIndividuals => '',
			:populationDeclinePast => 0,
			:timePeriodOfPastDecline => '',
			:populationDeclineFuture => 0,
			:timePeriodOfFutureDecline => '',
			:possiblyExtinctCandidate => false,
			:possiblyExtinct => false,
			:severelyFragmented => 'unkown'
		}
	end

	def schema
		@schema
	end
end

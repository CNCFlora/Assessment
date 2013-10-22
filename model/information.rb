class Information
	def inilialize
		@schema = {
			:currentPopulationTrend => '',
			:dateLastSeen => 0,
			:generationLength => '',
			:numberOfLocations => 0,
			:numberOfMatureIndividuals => '',
			:populationDeclinePast => 0,
			:timePeriodOfPastDecline => '',
			:populationDeclineFuture => 0,
			:timePeriodOfFutureDecline => '',
			:possiblyExtinctCandidate => false,
			:possiblyExtinct => false,
			:severelyFragmented => ''
		}
	end

	def schema
		@schema
	end
end
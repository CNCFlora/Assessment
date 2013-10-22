
class Change

	def initialize()
		@schema = {
			:reasonsForChange => '',
			:genuineChangeRecent => false,
			:genuineChangeSinceFirstTime => false,
			:noChangeSameCategoryAndCriteria => false,
			:noChangeSameCategoryAndDifferentCriteria => false,
			:nonGenuineChangeCriteriaRevisor => false,
			:nonGenuineChangeIncorrectDataUsedPreviously => false,
			:nonGenuineChangeKnowledgeOfCrite => false,
			:nonGenuineChangeNewInformation => false,
			:nonGenuineChangeOther => false,
			:nonGenuineChangeTaxonomy => false
		}
	end

	def schema
		@schema
	end
end

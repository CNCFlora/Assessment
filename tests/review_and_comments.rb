
require_relative 'base.rb'

describe "Review and comments system" do

    before (:each) do 
      before_each() 
    end

   after (:each) do after_each() end
   
    it "Can put assessment on review" do        
        roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
        post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

        post "/cncflora_test/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/cncflora_test/assessment/#{id}/status/review", {}

        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag("span.status",:text=>"review")
    end

    it "Can put assessment on comment" do        
        roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
        post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

        post "/cncflora_test/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/cncflora_test/assessment/#{id}/status/comment", {}

        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag("span.status",:text=>"comment")
    end

    it "Can publish assessment" do        
        roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
        post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

        post "/cncflora_test/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/cncflora_test/assessment/#{id}/status/published", {}

        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag("span.status",:text=>"published")
    end

    it "Can review an assessment" do
        roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
        post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

        post "/cncflora_test/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/cncflora_test/assessment/#{id}/status/review", {}

        post "/cncflora_test/assessment/#{id}/review", {:status=>"inconsistent",:comment=>"what?",:rationale=>"re rationale",:rewrite=>""}

        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag(".evaluator","Bruno")
        expect(last_response.body).to have_tag(".evaluation","inconsistent")
        expect(last_response.body).to have_tag("span.rationale",:text=>"")

        post "/cncflora_test/assessment/#{id}/review", {:status=>"inconsistent",:comment=>"what?",:rationale=>"re rationale2",:rewrite=>"yes"}

        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag("span.rationale",:text=>"re rationale2")

        post "/cncflora_test/assessment/#{id}", {:data=>{:rationale=>"Test rational"}.to_json}
        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag("span.rationale",:text=>"Test rational")
    end

    it "Can comment an assessment" do
        roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
        post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

        post "/cncflora_test/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/cncflora_test/assessment/#{id}/status/comments", {}

        post "/login", { :user => "{\"name\":\"diogo\", \"email\":\"diogo@cncflora.net\",\"roles\":[]}"}
        post "/cncflora_test/assessment/#{id}/comment",{:comment=>"Test comment"}

        get "/cncflora_test/assessment/#{id}"
        expect(last_response.body).to have_tag(".commenter","diogo")
        expect(last_response.body).to have_tag(".comment","Test comment")
    end

end

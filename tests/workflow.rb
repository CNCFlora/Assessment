require_relative 'base.rb'

describe "Test assessment creation and edition" do

   before (:each) do before_each() end

   #after (:each) do after_each() end
   
   it "Show right numbers in workflow" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/workflow"
      expect( last_response.body ).to have_tag("tr"){
          with_tag "td a", :text=>"ACANTHACEAE"
          with_tag "td.not_started", :text=> 1
          with_tag "td.open", :text=> 1
          with_tag "td.review", :text=> 0
          with_tag "td.comments", :text=> 0
          with_tag "td.published", :text=> 0
          with_tag "td.total", :text=> 2
      }
      expect( last_response.body ).to have_tag("tr"){
          with_tag "td a", :text=>"BROMELIACEAE"
          with_tag "td.not_started", :text=> 1
          with_tag "td.open", :text=> 0
          with_tag "td.review", :text=> 0
          with_tag "td.comments", :text=> 0
          with_tag "td.published", :text=> 0
          with_tag "td.total", :text=> 1
      }
   end

   it "Internal workflow" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/workflow/ACANTHACEAE" 

      expect( last_response.body ).to have_tag("h2","ACANTHACEAE (2)")
      expect( last_response.body ).to have_tag("li"){
          # Catch contain text rather than text.
          with_tag "a", :with=>{ :href=>"#not_started_no_profile" }, :text=>"Não iniciadas (sem perfil fechado) (1)"
          with_tag "a", :with=>{ :href=>"#not_started" }, :text=>"Não iniciadas (0)"
          with_tag "a", :with=>{ :href=>"#open" }, :text=>"Abertas (1)"
          with_tag "a", :with=>{ :href=>"#review" }, :text=>"Revisão (0)"
          with_tag "a", :with=>{ :href=>"#published" }, :text=>"Publicadas (0)"
          with_tag "a", :with=>{ :href=>"#comments" }, :text=>"Comentários (0)"
      }

      expect( last_response.body ).to have_tag( "div#not_started_no_profile ul li", :text=>"Justicia clivalis")
      expect( last_response.body ).to have_tag( "div#open ul li", :text=>"Aphelandra longiflora")
   end

   it "Can move assessment in workflow" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      post "/cncflora_test/assessment",{:scientificName=>"Justicia clivalis"}
      id = last_response.headers["location"].split("/").last

      post "/login", { :user => '{"name":"Diogo", "email":"bruno@cncflora.net","roles":[] }' }

      post "/cncflora_test/assessment/#{id}/status/review"
      get "/cncflora_test/assessment/#{id}"
      expect(last_response.body).to have_tag("span.status",:text=>"review")
      expect(last_response.body).to have_tag("span.contributor",:text=>"Diogo ; Bruno")

      post "/cncflora_test/assessment/#{id}/status/done"
      get "/cncflora_test/assessment/#{id}"
      expect(last_response.body).to have_tag("span.status",:text=>"done")
      expect(last_response.body).to have_tag("span.contributor",:text=>"Diogo ; Bruno")

   end
   
   it "Can move assessment in workflow for admin" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      post "/cncflora_test/assessment",{:scientificName=>"Justicia clivalis"}
      id = last_response.headers["location"].split("/").last

      post "/login", { :user => '{"name":"Diogo", "email":"bruno@cncflora.net","roles":[] }' }

      post "/cncflora_test/assessment/#{id}/change",{:status=>"review"}
      get "/cncflora_test/assessment/#{id}"
      expect(last_response.body).to have_tag("span.status",:text=>"review")
      expect(last_response.body).to have_tag("span.contributor",:text=>"Bruno")

      post "/cncflora_test/assessment/#{id}/change",{:status=>"done"}
      get "/cncflora_test/assessment/#{id}"
      expect(last_response.body).to have_tag("span.status",:text=>"done")
      expect(last_response.body).to have_tag("span.contributor",:text=>"Bruno")
   end

   it "Test button switches" do
   end

end


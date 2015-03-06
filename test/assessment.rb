
require_relative 'base.rb'

describe "Test assessment creation and edition" do

   before (:each) do before_each() end

   #after (:each) do after_each() end
   
   it "Restrict assessment creation" do
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).not_to have_tag("h3 i",:text => "Justicia clivalis")
     expect( last_response.body ).not_to have_tag("p",:text => "Não há avaliação para essa espécie.")
     expect( last_response.body ).not_to have_tag("button",:text => "Começar avaliação")

     post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).to have_tag("h3 i",:text => "Justicia clivalis")
     expect( last_response.body ).to have_tag("p",:text => "Não há avaliação para essa espécie.")
     expect( last_response.body ).not_to have_tag("button",:text => "Começar avaliação")

     # right role, wrong context: NOK
     roles = [{:context=>"cncflora",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).not_to have_tag("button",:text => "Começar avaliação")

     # right role, right context, wrong entity: NOK
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["BROMELIACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).not_to have_tag("button",:text => "Começar avaliação")

     # wrong role, right context, right entity: NOK
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'evaluator',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).not_to have_tag("button",:text => "Começar avaliação")

     # right role, right context, right entities: OK
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).to have_tag("button",:text => "Começar avaliação")

     # right role, right context, right entities: OK
     expect( last_response.body ).to have_tag("button",:text => "Começar avaliação")
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["Justicia clivalis"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     expect( last_response.body ).to have_tag("button",:text => "Começar avaliação")

   end

   it "Can create an assessment" do
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

     post "/cncflora_test/assessment",{:scientificName=>"Justicia clivalis"}
     follow_redirect!
     expect( last_response.body ).to have_tag("h3 i",:text => "Justicia clivalis")
     expect( last_response.body ).to have_tag("span",:class=>"creator",:text=>"Bruno")
     expect( last_response.body ).to have_tag("span",:class=>"contact",:text=>"bruno@cncflora.net")
     expect( last_response.body ).to have_tag("a",:text => "Editar")
   end

   it "Can restrict edit" do
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

     post "/cncflora_test/assessment",{:scientificName=>"Justicia clivalis"}

     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     follow_redirect!
     expect( last_response.body ).to have_tag("a",:text => "Editar")

     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["Justicia clivalis"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno2\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     follow_redirect!
     expect( last_response.body ).to have_tag("a",:text => "Editar")

     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>[]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno2\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}
     get "/cncflora_test/specie/Justicia+clivalis"
     follow_redirect!
     expect( last_response.body ).not_to have_tag("a",:text => "Editar")
   end

   it "Can edit and have metadata" do
     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Bruno\", \"email\":\"bruno@cncflora.net\",\"roles\":#{roles}}"}

     post "/cncflora_test/assessment",{:scientificName=>"Justicia clivalis"}
     id = last_response.headers["location"].split("/").last

     get "/cncflora_test/assessment/#{id}/edit"
     expect(last_response.body).to have_tag("button",:text=>"Enviar para revisão")
     expect(last_response.body).to have_tag("button",:text=>"Salvar")

     roles = [{:context=>"cncflora_test",:roles=>[{:role=>'assessor',:entities=>["ACANTHACEAE"]}]}].to_json
     post "/login", { :user => "{\"name\":\"Diogo\", \"email\":\"diogo@cncflora.net\",\"roles\":#{roles}}"}

     post "/cncflora_test/assessment/#{id}", {:data=>{:rationale=>"Test assessor"}.to_json}

     get "/cncflora_test/assessment/#{id}"
     expect(last_response.body).to have_tag("span",:class=>"contributor",:text=>"Diogo ; Bruno")
     expect(last_response.body).to have_tag("span",:class=>"rationale",:text=>"Test assessor")
     expect(last_response.body).to have_tag("span",:class=>"assessor",:text=>"Bruno")
   end
  
end



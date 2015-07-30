
require_relative 'base.rb'

describe "Test families and species listing" do

  before(:each) do before_each() end

  after (:each) do after_each() end

  it "Can list families and species" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/families"
      expect( last_response.body ).to have_tag(:a,:text => 'ACANTHACEAE')
      expect( last_response.body ).to have_tag(:a,:text => 'BROMELIACEAE')

      get "/cncflora_test/family/ACANTHACEAE"
      expect( last_response.body ).to have_tag(:a,:text => 'Justicia clivalis')
      expect( last_response.body ).to have_tag(:a,:text => "Aphelandra longiflora")
      expect( last_response.body ).not_to have_tag(:a,:text => "Aphelandra longiflora2")
      expect( last_response.body ).not_to have_tag(:a,:text => "Uma bromelia")

      get "/cncflora_test/family/BROMELIACEAE"
      expect( last_response.body ).to have_tag(:a,:text => "Uma bromelia")
      expect( last_response.body ).not_to have_tag(:a,:text => "Aphelandra longiflora")

      get "/cncflora_test/specie/Justicia+clivalis"
      expect( last_response.body ).to have_tag("h3 i",:text => "Justicia clivalis")
      expect( last_response.body ).to have_tag("p",:text => "Não há avaliação para essa espécie.")

      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!
      expect( last_response.body ).to have_tag("h3 i",:text => "Aphelandra longiflora")
      expect( last_response.body ).not_to have_tag("p",:text => "Não há avaliação para essa espécie.")
  end

end


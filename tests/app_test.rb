ENV['RACK_ENV'] = 'test'

require_relative '../app'
require_relative '../model/assessment'
require_relative '../model/couchdb'

require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app" do

    before(:all) do
        @couch = CouchDB.new Sinatra::Application.settings.couchdb
        post "/login", {:user => '{"name":"Bruno","email":"bruno@cncflora.net","roles":[{"role":"assessor"}]}'}

        # remember to push the datahub...

        @taxon_id = "taxon1"
        @couch.create({:metadata=>{:type=>"taxon",:contributor=>"test",:created=>0,:valid=>true,:identifier=>@taxon_id},
                       :_id => @taxon_id, :taxonID => @taxon_id,
                       :kingdom=> "", :order=> "", :phylum=> "", :class=> "",
                       :family=> "ACANTHACEAE", :genus=>"Justicia",
                       :scientificName=>"Justicia clivalis",
                       :scientificNameAuthorship=>"S.Profice",
                       :taxonRank=>"species", :taxonomicStatus=>"accepted"})
        @profile_id = "profile1"
        @couch.create({:metadata=>{:type=>"profile",:contributor=>"test",:created=>0,:valid=>true,:identifier=>@profile_id},
                       :taxon=>{:family=>"ACANTHACEAE",:scientificName=>"Justicia clivalis",:scientificNameAuthorship=>"S.Profice",:lsid=>@taxon_id},
                       :_id=> @profile_id})
    end

    after(:all) do
        @couch.delete(@couch.get(@profile_id))
        @couch.delete(@couch.get(@taxon_id))
    end

    it "Can list families and species" do
        get "/families"
        last_response.body.should have_tag(:a,:text => 'ACANTHACEAE')

        get "/family/ACANTHACEAE"
        last_response.body.should have_tag(:a,:text => 'Justicia clivalis')
    end

    it "Can create assessment for specie" do
        get "/specie/#{@taxon_id}"
        last_response.status.should be(200)
        last_response.body.should have_tag(:form)

        post "/assessment", {:lsid=>@taxon_id}
        last_response.status.should eq(302)
        id = last_response.headers["location"].split("/").last
        follow_redirect!
        last_response.body.should have_tag("h3 i",:text => "Justicia clivalis")

        get "/specie/#{@taxon_id}"
        last_response.status.should eq(302)
        follow_redirect!
        last_response.body.should have_tag("h3 i",:text => "Justicia clivalis")

        @couch.delete(@couch.get(id))
    end

    it "Can edit assessment" do
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last

        assmnt = @couch.get(id)

        post "/assessment/#{id}", {:data=>{:assessor=>"Test assessor"}.to_json}
        response = MultiJson.load(last_response.body,:symbolize_keys =>true)
        response[:assessor].should eq('Test assessor')

        # TODO:test metadata update...
        post "/logout"
        post "/login", {:user => '{"name":"Diogo","email":"diogok@cncflora.net","roles":[{"role":"assessor"}]}'}
        post "/assessment/#{id}", {:data=>{:assessor=>"Test assessor2"}.to_json}
        response = MultiJson.load(last_response.body,:symbolize_keys =>true)
        response[:assessor].should eq('Test assessor2')
        
        doc = @couch.get(id)
        doc[:metadata][:contributor].split(" ; ").should =~ ['Bruno','Diogo']

        @couch.delete(@couch.get(id))
    end

=begin
    it "Can review assessment" do        
        assessment = @couch.create @assessment
        id = assessment[:_id]
        put "/assessments/#{id}/status/review", assessment
        last_response.status.should == 204
    end

    it "Can comment assessment" do
        assessment = @couch.create @assessment
        id = assessment[:_id]
        put "/assessments/#{id}/status/comment", assessment
        last_response.status.should == 204
    end

    it "Can publish assessment" do
        assessment = @couch.create @assessment
        id = assessment[:_id]
        put "/assessments/#{id}/status/publish", assessment
        last_response.status.should == 204
    end

    it "Can list species without assessment for given family" do        
    end

    it "Can list species with open assessment for given family" do
    end

    it "Can list species with assessment to review" do
    end

    it "Can list species with assessment to comment" do
    end

    it "Can list species with assessment published" do
    end

    it "Can move assessments in workflow" do
    end
=end

end

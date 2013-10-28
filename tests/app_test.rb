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

    before(:each) do
        post "/login", {:user => '{"name":"Bruno","email":"bruno@cncflora.net","roles":[{"role":"assessor"}]}'}
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

        assessment = @couch.get(id)
        assessment[:metadata][:created].should eq(assessment[:dateOfAssessment])
        assessment[:metadata][:modified].should eq(assessment[:dateOfAssessment])
        assessment[:assessor].should eq('Bruno')

        @couch.delete(@couch.get(id))
    end

    it "Can edit assessment" do
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last

        assmnt = @couch.get(id)

        post "/assessment/#{id}", {:data=>{:rationale=>"Test assessor"}.to_json}
        response = MultiJson.load(last_response.body,:symbolize_keys =>true)
        response[:rationale].should eq('Test assessor')

        post "/logout"
        post "/login", {:user => '{"name":"Diogo","email":"diogok@cncflora.net","roles":[{"role":"assessor"}]}'}
        post "/assessment/#{id}", {:data=>{:rationale=>"Test assessor2"}.to_json}
        response = MultiJson.load(last_response.body,:symbolize_keys =>true)
        response[:rationale].should eq('Test assessor2')
        response[:metadata][:contributor].split(" ; ").should =~ ['Bruno','Diogo']

        @couch.delete(@couch.get(id))
    end

    it "Can put assessment on review" do        
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("open")
        post "/assessment/#{id}/status/review", {}
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("review")        
        @couch.delete(assessment)
    end

    it "Can put assessment on comment" do        
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last
        post "/assessment/#{id}/status/comment", {}
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("comment")
        @couch.delete(assessment)
    end

    it "Can put assessment on publish" do        
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last
        post "/assessment/#{id}/status/publish", {}
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("publish")
        @couch.delete(assessment)
    end

    it "Can review an assessment" do
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last

        post "/assessment/#{id}/review", {:status=>"inconsistent",:comment=>"what?",:rationale=>"re rationale"}

        assessment = @couch.get(id)
        assessment[:evaluator].should eq("Bruno")
        assessment[:review][:status].should eq("inconsistent")
        assessment[:review][:comment].should eq("what?")
        assessment[:review][:rationale].should eq("re rationale")

        @couch.delete(assessment)
    end

    it "Can comment an assessment" do
        post "/assessment", {:lsid=>@taxon_id}
        id = last_response.headers["location"].split("/").last

        post "/assessment/#{id}/comment",{:comment=>"Test comment"}
        assessment = @couch.get(id)
        assessment[:comments].length.should eq(1)
        assessment[:comments][0][:comment].should eq('Test comment')
        assessment[:comments][0][:creator].should eq('Bruno')

        post "/logout"
        post "/login", {:user => '{"name":"Diogo","email":"diogok@cncflora.net","roles":[{"role":"assessor"}]}'}

        post "/assessment/#{id}/comment",{:comment=>"Test comment2"}
        assessment = @couch.get(id)
        assessment[:comments].length.should eq(2)
        assessment[:comments][0][:comment].should eq('Test comment')
        assessment[:comments][0][:creator].should eq('Bruno')
        assessment[:comments][1][:comment].should eq('Test comment2')
        assessment[:comments][1][:creator].should eq('Diogo')

        @couch.delete(assessment)
    end

=begin    
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
=end

end

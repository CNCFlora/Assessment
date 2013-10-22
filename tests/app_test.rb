require_relative '../app'
require_relative '../model/assessment'
require_relative '../model/couchdb'
require 'rspec'
require 'rack/test'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app" do

    before(:each) do
        url = "http://bruno:senha@localhost:5984/test_rb"
        @couch = CouchDB.new url
        @assessment = Assessment.new.schema
        post "/login", {:user => '{"name":"Bruno","email":"bruno@cncflora.net"}'}        
    end

    # it "Can render the template with data" do
    #     get "/"
    #     print last_response.body
    #     last_response.should be_ok
    #     last_response.body.should include( "Ola, bar!" )
    # end
    it "Can list families and species" do
    end

    it "Can list families for given user" do
    end

    it "Can create assessment for profile" do
        assessment = Assessment.new.schema
        assessment[:profile] = "profileTestCreate" 
        post "/assessments", assessment
        last_response.status.should == 201

        # id = last_response.body.split("/").last
        # puts "id = #{id}"
        # get "/assessments/#{id}"
        # doc = JSON.parse(last_response.body)
        # puts "doc = #{doc[:profile]}"
        # expect(doc[:profile]).to eq('profileTestCreate')
    end

    it "Can edit assessment" do
        doc = Assessment.new.schema
        assessment = @couch.create doc
        id = assessment[:_id] 
        assessment[:criteria] = 'criteriaTestUpdate'
        assessment[:category] = 'categoryTestUpdate'
        put "/assessments/#{id}", assessment
        last_response.status.should == 204
    end

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

end
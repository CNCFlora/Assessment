require_relative '../app'
require 'rspec'
require 'rack/test'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app" do
    it "Can render the template with data" do
        get "/"
        print last_response.body
        last_response.should be_ok
        last_response.body.should include( "Ola, bar!" )
    end
    it "Can list families and species" do
    end
    it "Can list families for given user" do
    end
    it "Can create assessment for profile" do
    end
    it "Can edit assessment" do
    end
    it "Can review assessment" do
    end
    it "Can comment assessment" do
    end
    it "Can publish assessment" do
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


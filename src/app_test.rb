Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

ENV['RACK_ENV'] = 'test'

require_relative 'app'

require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'
require 'json'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app" do

    before(:all) do

        @couch = Couchdb.new Sinatra::Application.settings.couchdb

        @couch.create({:metadata=> 
                        {
                            :type=>"taxon",
                            :creator=>"test",
                            :contributor=>"test",
                            :created=>Time.now.to_i,
                            :modified=>Time.now.to_i,
                            :valid=>true,
                            :identifier=>"taxon1"
                        },
                       :_id => "taxon1", 
                       :taxonID => "taxon1",
                       :family=> "ACANTHACEAE", 
                       :scientificName=>"Justicia clivalis S.Profice",
                       :scientificNameWithoutAuthorship=>"Justicia clivalis",
                       :scientificNameAuthorship=>"S.Profice",
                       :taxonRank=>"species", 
                       :taxonomicStatus=>"accepted"
        })

        @couch.create({:metadata=> 
                        {
                            :type=>"taxon",
                            :creator=>"test",
                            :contributor=>"test",
                            :created=>Time.now.to_i,
                            :modified=>Time.now.to_i,
                            :valid=>true,
                            :identifier=>"taxon2"
                        },
                       :_id => "taxon2", 
                       :taxonID => "taxon2",
                       :family=> "ACANTHACEAE", 
                       :scientificName=>"Aphelandra longiflora S.Profice",
                       :scientificNameWithoutAuthorship=>"Aphelandra longiflora",
                       :scientificNameAuthorship=>"S.Profice",
                       :taxonRank=>"species", 
                       :taxonomicStatus=>"accepted"
        })

        @couch.create({:metadata=> 
                        {
                            :type=>"profile",
                            :creator=>"test",
                            :contributor=>"test",
                            :created=>Time.now.to_i,
                            :modified=>Time.now.to_i,
                            :valid=>true,
                            :status=>"done",
                            :identifier=>"profile1"
                        },
                       :_id => "profile1", 
                       :taxon => {
                           :family=> "ACANTHACEAE", 
                           :scientificName=>"Justicia clivalis S.Profice",
                           :scientificNameWithoutAuthorship=>"Justicia clivalis",
                           :scientificNameAuthorship=>"S.Profice",
                       }

        })
       sleep 2
    end

    before(:each) do
        post "/login", {:user => '{"name":"Bruno","email":"bruno@cncflora.net","roles":[{"role":"assessor","entities":["ACANTHACEAE"]}]}'}
    end

    after(:all) do
        @couch.get_all().each{|d|
            @couch.delete(d)
        }
    end

    it "Can list families and species" do
        get "/families"
        expect( last_response.body ).to have_tag(:a,:text => 'ACANTHACEAE')

        get "/family/ACANTHACEAE"
        expect( last_response.body ).to have_tag(:a,:text => 'Justicia clivalis')
        expect( last_response.body ).to have_tag(:a,:text => "Aphelandra longiflora")

        get "/specie/Justicia+clivalis"
        expect( last_response.body ).to have_tag("h3 i",:text => "Justicia clivalis")
    end

    it "Can create assessment for specie" do
        get "/specie/Justicia%20Clivalis"
        expect( last_response.status ).to eq(200)
        expect( last_response.body ).to have_tag(:form)

        post "/assessment", {:scientificName=>"Justicia clivalis"}
        expect( last_response.status ).to eq(302)
        id = last_response.headers["location"].split("/").last
        sleep 1
        follow_redirect!
        expect( last_response.body ).to have_tag("h3 i",:text => "Justicia clivalis")

        get "/specie/Justicia+clivalis"
        expect(last_response.status).to eq(302)
        follow_redirect!
        expect(last_response.body).to have_tag("h3 i",:text => "Justicia clivalis")

        assessment = @couch.get(id)
        expect( assessment[:metadata][:created] ).to eq(assessment[:dateOfAssessment])
        expect( assessment[:metadata][:modified] ).to eq(assessment[:dateOfAssessment])
        expect( assessment[:assessor] ).to eq('Bruno')

        @couch.delete(@couch.get(id))
    end

    it "Can edit assessment" do
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        assmnt = @couch.get(id)

        post "/assessment/#{id}", {:data=>{:rationale=>"Test assessor"}.to_json}
        response = JSON.parse(last_response.body)
        expect( response["rationale"] ).to eq('Test assessor')

        post "/logout"
        post "/login", {:user => '{"name":"Diogo","email":"diogok@cncflora.net","roles":[{"role":"assessor"}]}'}
        post "/assessment/#{id}", {:data=>{:rationale=>"Test assessor2"}.to_json}
        response = JSON.parse(last_response.body,:symbolize_keys =>true)
        expect( response["rationale"] ).to eq('Test assessor2')
        expect( response["metadata"]["contributor"].split(" ; ") ).to  eq( ['Diogo',"Bruno"] )

        @couch.delete(@couch.get(id))
    end

    it "Can put assessment on review" do        
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("open")
        post "/assessment/#{id}/status/review", {}
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("review")        
        @couch.delete(assessment)
    end

    it "Can put assessment on comment" do        
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last
        post "/assessment/#{id}/status/comment", {}
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("comment")
        @couch.delete(assessment)
    end

    it "Can put assessment on publish" do        
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last
        post "/assessment/#{id}/status/publish", {}
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("publish")
        @couch.delete(assessment)
    end

    it "Can review an assessment" do
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/assessment/#{id}/review", {:status=>"inconsistent",:comment=>"what?",:rationale=>"re rationale"}

        assessment = @couch.get(id)
        expect( assessment[:evaluator] ).to eq("Bruno")
        expect( assessment[:review][:status] ).to eq("inconsistent")
        expect( assessment[:review][:comment] ).to eq("what?")
        expect( assessment[:review][:rationale] ).to eq("re rationale")

        @couch.delete(assessment)
    end

    it "Can comment an assessment" do
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/assessment/#{id}/comment",{:comment=>"Test comment"}
        assessment = @couch.get(id)
        expect( assessment[:comments].length ).to eq(1)
        expect( assessment[:comments][0][:comment] ).to eq('Test comment')
        expect( assessment[:comments][0][:creator] ).to eq('Bruno')

        post "/logout"
        post "/login", {:user => '{"name":"Diogo","email":"diogok@cncflora.net","roles":[{"role":"assessor"}]}'}

        post "/assessment/#{id}/comment",{:comment=>"Test comment2"}
        assessment = @couch.get(id)
        expect( assessment[:comments].length ).to eq(2)
        expect( assessment[:comments][0][:comment] ).to eq('Test comment')
        expect( assessment[:comments][0][:creator] ).to eq('Bruno')
        expect( assessment[:comments][1][:comment] ).to eq('Test comment2')
        expect( assessment[:comments][1][:creator] ).to eq('Diogo')

        @couch.delete(assessment)
    end

    it "Can change status of assessment" do
        post "/assessment", {:scientificName=>"Justicia clivalis"}
        id = last_response.headers["location"].split("/").last

        post "/assessment/#{id}/change", { :status=>"comment" } 
        assessment = @couch.get(id)
        expect(assessment[:metadata][:status]).to eq("comment")
        @couch.delete(assessment)
    end

end

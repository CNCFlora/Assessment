Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

ENV['RACK_ENV'] = 'test'

require_relative '../src/app'

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

        # Taxons of LORANTHACEAE family.
        @couch.create( { :metadata=>{ :type=>"taxon", :creator=>"test", :created=>Time.now.to_i,},
                       :family=> "LORANTHACEAE", :scientificNameWithoutAuthorship=>"Struthanthus planaltinae",:taxonRank=>"species", :taxonomicStatus=>"accepted"})
        @couch.create( { :metadata=>{ :type=>"taxon", :creator=>"test", :created=>Time.now.to_i,},
                       :family=> "LORANTHACEAE", :scientificNameWithoutAuthorship=>"Struthanthus pusillifolius",:taxonRank=>"species", :taxonomicStatus=>"accepted"})
        @couch.create( { :metadata=>{ :type=>"taxon", :creator=>"test", :created=>Time.now.to_i,},
                       :family=> "LORANTHACEAE", :scientificNameWithoutAuthorship=>"Psittacanthus acinarius",:taxonRank=>"species", :taxonomicStatus=>"accepted"})
        @couch.create( { :metadata=>{ :type=>"taxon", :creator=>"test", :created=>Time.now.to_i,},
                       :family=> "LORANTHACEAE", :scientificNameWithoutAuthorship=>"Oryctina eubrachioides",:taxonRank=>"species", :taxonomicStatus=>"accepted"})
        @couch.create( { :metadata=>{ :type=>"taxon", :creator=>"test", :created=>Time.now.to_i,},
                       :family=> "LORANTHACEAE", :scientificNameWithoutAuthorship=>"Struthanthus microstylus",:taxonRank=>"species", :taxonomicStatus=>"accepted"})
        # Assessments of LORANTHACEAE family.
        @couch.create( {
            :assessor=>"foo", :evaluator=>"bar", :category=>"EN", :criteria=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
            :metadata=>{:contributor=>"foo", :created=>1386183678, :creator=>"foo", :type=>"assessment", :status=>"open"}, 
            :taxon=>{:lsid=>"1", :family=>"LORANTHACEAE", :scientificNameWithoutAuthorship=>"Struthanthus planaltinae"}
        })

        @couch.create( {
            :assessor=>"foo", :evaluator=>"bar", :category=>"EN", :criteria=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
            :metadata=>{:contributor=>"foo", :created=>1386183678, :creator=>"foo", :type=>"assessment", :status=>"review"}, 
            :taxon=>{:lsid=>"1", :family=>"LORANTHACEAE", :scientificNameWithoutAuthorship=>"Struthanthus pusillifolius"}
        })

        @couch.create( {
            :assessor=>"foo", :evaluator=>"bar", :category=>"EN", :criteria=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
            :metadata=>{:contributor=>"foo", :created=>1386183678, :creator=>"foo", :type=>"assessment", :status=>"published"}, 
            :taxon=>{:lsid=>"1", :family=>"LORANTHACEAE", :scientificNameWithoutAuthorship=>"Psittacanthus acinarius"}
        })

        @couch.create( {
            :assessor=>"foo", :evaluator=>"bar", :category=>"EN", :criteria=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
            :metadata=>{:contributor=>"foo", :created=>1386183678, :creator=>"foo", :type=>"assessment", :status=>"comments"}, 
            :taxon=>{:lsid=>"1", :family=>"LORANTHACEAE", :scientificNameWithoutAuthorship=>"Oryctina eubrachioides"}
        })

        @couch.create( 
            :assessor=>"foo", :evaluator=>"bar", :category=>"EN", :criteria=>"B1ab(i,ii,iii,v)+2ab(i,ii,iii,v)", 
            :metadata=>{:contributor=>"foo", :created=>1386183678, :creator=>"foo", :type=>"assessment", :status=>"not_started"}, 
            :taxon=>{:lsid=>"1", :family=>"LORANTHACEAE", :scientificNameWithoutAuthorship=>"Struthanthus microstylus"} 
        )

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

    it "Can get workflow" do
        get "/workflow"
        expect( last_response.status ).to eq(200)
        expect( last_response.body ).to have_tag("table tbody tr#LORANTHACEAE"){
            with_tag "td a", :with=>{:href=>"/workflow/LORANTHACEAE"}
            with_tag "td#open", :text=> 1
            with_tag "td#review", :text=> 1
            with_tag "td#published", :text=> 1
            with_tag "td#comments", :text=> 1
            with_tag "td#not_started", :text=> 1
            with_tag "td#total", :text=> 5
        }
    end

    it "Can get workflow details of a family" do
        get "workflow/LORANTHACEAE" 
        expect( last_response.status ).to eq(200)
        expect( last_response.body ).to have_tag("div h2","LORANTHACEAE (5)")
        expect( last_response.body ).to have_tag("div ul li"){
            # Catch contain text rather than text.
            with_tag "a", :with=>{ :href=>"#empty" }, :text=>"Não iniciadas (1)"
            with_tag "a", :with=>{ :href=>"#open" }, :text=>"Abertas (1)"
            with_tag "a", :with=>{ :href=>"#review" }, :text=>"Revisão (1)"
            with_tag "a", :with=>{ :href=>"#published" }, :text=>"Publicadas (1)"
            with_tag "a", :with=>{ :href=>"#comments" }, :text=>"Comentários (1)"
        }
        expect( last_response.body ).to have_tag( "div#not_started ul li", :text=>"Struthanthus microstylus")
        expect( last_response.body ).to have_tag( "div#open ul li", :text=>"Struthanthus planaltinae")
        expect( last_response.body ).to have_tag( "div#review ul li", :text=>"Struthanthus pusillifolius")
        expect( last_response.body ).to have_tag( "div#published ul li", :text=>"Psittacanthus acinarius")
        expect( last_response.body ).to have_tag( "div#comments ul li", :text=>"Oryctina eubrachioides")
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

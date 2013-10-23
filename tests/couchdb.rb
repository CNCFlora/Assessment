require_relative '../model/couchdb.rb'
require 'rspec'

describe "CouchDB abstraction layer" do

    before(:each) do
        @url = "http://tester:tester@localhost:5984/test_rb"
        @couch = CouchDB.new @url
    end

    after(:each) do
        #docs = @couch.get_all
        #docs.each { |doc| @couch.delete(doc) }
    end

    it "Connect to database" do
        db = CouchDB.new @url
        expect(db[:db_name]).to eq('test_rb')
    end

    it "Can CRUD on database" do
        doc = @couch.create ( {:metadata => {:type => "assessment"}, :foo => "bar"} )
        expect(doc[:_rev]).not_to eq(nil)

        re_doc = @couch.get(doc[:_id])
        expect(re_doc[:foo]).to eq('bar')

        re_doc[:foo] = "baz"
        @couch.update re_doc

        re_doc = @couch.get ( doc[:_id] )
        expect(re_doc[:foo]).to eq('baz')

        @couch.delete re_doc

        re_doc = @couch.get doc[:_id]
        expect(re_doc).to be_nil 
    end

    it "Can query views" do
        begin
            design  = {:_id => "_design/test", 
                       :views => {:by_type => {:map => "function(doc) { emit(doc.metadata.type,doc); }"}}};
            @couch.create(design)
        rescue RestClient::Conflict
            print "view already exists"
        end

        doc = @couch.create({:metadata => {:type => "assessment"}, :foo => "bar"})

        assessments = @couch.view('test','by_type')
        expect(assessments.length).to eq(1)

        assessments = @couch.view('test','by_type',{:key=>"assessment"})
        expect(assessments.length).to eq(1)

        assessments = @couch.view('test','by_type',{:key=>"nope"})
        expect(assessments.length).to eq(0)

        #@couch.delete(doc)
        #@couch.delete(design)
    end

end


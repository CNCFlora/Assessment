
require_relative 'base.rb'

describe "Test checklist switch and login/logout" do

   # before (:each) do before_each() end

   # after (:each) do after_each() end

    it "Restrict login at home" do
      get "/"
      expect(last_response.body).to have_tag('h2',:text=>'Necessário fazer login.')
      expect(last_response.body).not_to have_tag('a',:text=>'Recortes')
      expect(last_response.body).not_to have_tag('a',:text=>'Workflow')
      expect(last_response.body).not_to have_tag('a',:text=>'Familias')
    end

    it "List checklists after login at home" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/"

      expect(last_response.body).not_to have_tag('h2',:text=>'Necessário fazer login')
      expect(last_response.body).to have_tag('a',:text=>'Recortes')
      expect(last_response.body).not_to have_tag('a',:text=>'Workflow')
      expect(last_response.body).not_to have_tag('a',:text=>'Familias')

      #expect(last_response.body).to have_tag('a',:text=>'CNCFLORA')
      expect(last_response.body).to have_tag('a',:text=>'CNCFLORA TEST')
    end

    it "Change checklist active" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/families"

      expect(last_response.body).to have_tag('a',:text=>'Recortes')
      expect(last_response.body).to have_tag('a',:text=>'Workflow')
      expect(last_response.body).to have_tag('a',:text=>'Familias')

      expect(last_response.body).to have_tag('span',:class=>'db',:text=>'Recorte: CNCFLORA TEST')

      get "/cncflora_test/workflow"

      expect(last_response.body).to have_tag('a',:text=>'Recortes')
      expect(last_response.body).to have_tag('a',:text=>'Workflow')
      expect(last_response.body).to have_tag('a',:text=>'Familias')

      expect(last_response.body).to have_tag('span',:class=>'db',:text=>'Recorte: CNCFLORA TEST')
    end

end


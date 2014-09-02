
post "/assessment" do    
    spp = search("taxon","scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]

    assessment = {}

    assessment[:dateOfAssessment] = Time.now.to_i
    assessment[:assessor] = session[:user]["name"]

    assessment[:taxon] = {}
    assessment[:taxon][:family] = spp["family"]
    assessment[:taxon][:scientificName] = spp["scientificName"]
    assessment[:taxon][:scientificNameWithoutAuthorship] = spp["scientificNameWithoutAuthorship"]
    assessment[:taxon][:scientificNameAuthorship] = spp["scientificNameAuthorship"]

    assessment[:metadata] = {}
    assessment[:metadata][:creator] = session[:user]["name"]
    assessment[:metadata][:contributor] = session[:user]["name"]
    assessment[:metadata][:contact] = session[:user]["email"]
    assessment[:metadata][:modified] = Time.now.to_i
    assessment[:metadata][:created] = Time.now.to_i
    assessment[:metadata][:status] = "open"
    assessment[:metadata][:type] = "assessment"

    assessment = settings.conn.create(assessment)

    redirect to("/assessment/#{assessment[:_id]}")
end

get "/assessment/:id" do

    assessment = settings.conn.get(params[:id])

    #profile = db.get(assessment[:profile])
    #profile={}
    profile=nil
    #profile= search("profile","taxon.scientificNameWithoutAuthorship:\"#{ assessment.taxon.scientificNameWithoutAuthorship}\"")[0]
    
    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    if assessment[:review] && assessment[:review][:rationale].length >=1 
        assessment[:rationale] = assessment[:review][:rationale]
    end

    assessment["status-#{assessment[:metadata][:status]}"] = true

    owner = assessment[:metadata][:creator] == session[:user]["name"]

    view :view, {:assessment => assessment, :specie_profile => profile, :owner=>owner}
end

get "/assessment/:id/edit" do
    assessment = settings.conn.get(params[:id])

    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    schema = JSON.parse(File.read("src/schema.json", :encoding => "BINARY"))

    schema["properties"].delete("metadata")
    schema["properties"].delete("taxon")
    schema["properties"].delete("profile")
    schema["properties"].delete("dateOfAssessment")
    schema["properties"].delete("review")
    schema["properties"].delete("comments")
    view :edit, {:assessment => assessment,:schema=> JSON.dump(schema),:data => JSON.dump(assessment)}
end

post "/assessment/:id" do    
    assessment = settings.conn.get(params[:id])

    contributors = assessment[:metadata][:contributor].split(" ; ")
    contributors = [session[:user]["name"]].concat(contributors).uniq().select {|c| c != nil && c.length >= 2} 
    assessment[:metadata][:contributor] = contributors.join(" ; ")

    contacts = assessment[:metadata][:contact].split(" ; ")
    contacts = [session[:user]["email"]].concat(contacts).uniq().select {|c| c != nil && c.length >= 2}
    assessment[:metadata][:contact] = contacts.join(" ; ")

    assessment[:metadata][:modified] = Time.now.to_i

    data = JSON.parse(params[:data])
    data[:_rev] = assessment[:_rev]
    data[:_id] = assessment[:_id]
    data["metadata"] = assessment[:metadata]
    data["taxon"] = assessment[:taxon]
    data["profile"] = assessment[:profile]

    if assessment["review"]
        data["review"] = assessment[:review]
    end

    if assessment["comments"]
        data["comments"] = assessment[:comments]
    end

    settings.conn.update(data)

    content_type :json
    JSON.dump(data)
end



post "/:db/assessment" do    
    require_logged_in
    spp = search(params[:db],"taxon","scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]

    id = SecureRandom.uuid

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
    assessment[:metadata][:identifier]= id

    assessment[:_id]=id;

    r = http_put("#{settings.couchdb}/#{params[:db]}/#{id}",assessment)

    redirect to("#{settings.base}/#{params[:db]}/assessment/#{id}")
end

get "/:db/assessment/:id" do
    require_logged_in

    assessment = http_get("#{settings.couchdb}/#{params[:db]}/#{params[:id]}")

    assessment["metadata"]["created_date"] = Time.at(assessment["metadata"]["created"]).to_s[0..9]
    assessment["metadata"]["modified_date"] = Time.at(assessment["metadata"]["modified"]).to_s[0..9]

    if assessment["review"] && assessment["review"]["rationale"].length >=1 
        assessment["rationale"] = assessment["review"]["rationale"]
    end

    assessment["status-#{assessment["metadata"]["status"]}"] = true

    specie=assessment["taxon"]

    can_edit = assessment["metadata"]["creator"] == session["user"]["name"]
    session[:user]["roles"].each{|r|
      if r["context"].downcase==params[:db].downcase then
        r["roles"].each{|role|
          if role["role"].downcase == "assessor" then
            role["entities"].each {|e|
              if e.downcase == specie["scientificName"].downcase || e.downcase == specie["scientificNameWithoutAuthorship"].downcase || e.downcase == specie["family"].downcase then
                can_edit=true;
              end
            }
          end
        }
      end
    }

    view :view, {:assessment => assessment, :can_edit=>can_edit,:db=>params[:db]}
end

get "/:db/assessment/:id/edit" do
    require_logged_in

    assessment = http_get("#{settings.couchdb}/#{params[:db]}/#{params[:id]}")

    assessment["metadata"]["created_date"] = Time.at(assessment["metadata"]["created"]).to_s[0..9]
    assessment["metadata"]["modified_date"] = Time.at(assessment["metadata"]["modified"]).to_s[0..9]

    schema = JSON.parse(File.read("src/schema.json", :encoding => "BINARY"))

    schema["properties"].delete("metadata")
    schema["properties"].delete("taxon")
    schema["properties"].delete("profile")
    schema["properties"].delete("dateOfAssessment")
    schema["properties"].delete("review")
    schema["properties"].delete("comments")
    view :edit, {:assessment => assessment,:schema=> JSON.dump(schema),:data => JSON.dump(assessment),:db=>params[:db]}
end

post "/:db/assessment/:id" do    
    require_logged_in

    assessment = http_get("#{settings.couchdb}/#{params[:db]}/#{params[:id]}")

    contributors = assessment["metadata"]["contributor"].split(" ; ")
    contributors = [session[:user]["name"]].concat(contributors).uniq().select {|c| c != nil && c.length >= 2} 
    assessment["metadata"]["contributor"] = contributors.join(" ; ")

    contacts = assessment["metadata"]["contact"].split(" ; ")
    contacts = [session["user"]["email"]].concat(contacts).uniq().select {|c| c != nil && c.length >= 2}
    assessment["metadata"]["contact"] = contacts.join(" ; ")

    assessment["metadata"]["modified"] = Time.now.to_i

    data = JSON.parse(params["data"])
    data["_rev"] = assessment["_rev"]
    data["_id"] = assessment["_id"]
    data["metadata"] = assessment["metadata"]
    data["taxon"] = assessment["taxon"]
    data["profile"] = assessment["profile"]

    if assessment["review"]
        data["review"] = assessment["review"]
    end

    if assessment["comments"]
        data["comments"] = assessment["comments"]
    end

    r = http_put("#{settings.couchdb}/#{params[:db]}/#{params[:id]}",data)

    content_type :json
    JSON.dump(data)
end


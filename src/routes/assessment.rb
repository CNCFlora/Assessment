
post "/:db/assessment" do    
    require_logged_in
    spp = search(params[:db],"taxon","scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]

    id = SecureRandom.uuid

    assessment = {}

    assessment["dateOfAssessment"] = Time.now.to_i
    assessment["assessor"] = session[:user]["name"]

    assessment["taxon"] = {}
    assessment["taxon"]["family"] = spp["family"]
    assessment["taxon"]["scientificName"] = spp["scientificName"]
    assessment["taxon"]["scientificNameWithoutAuthorship"] = spp["scientificNameWithoutAuthorship"]
    assessment["taxon"]["scientificNameAuthorship"] = spp["scientificNameAuthorship"]

    assessment["metadata"] = {}
    assessment["metadata"]["creator"] = session[:user]["name"]
    assessment["metadata"]["contributor"] = session[:user]["name"]
    assessment["metadata"]["contact"] = session[:user]["email"]
    assessment["metadata"]["modified"] = Time.now.to_i
    assessment["metadata"]["created"] = Time.now.to_i
    assessment["metadata"]["status"] = "open"
    assessment["metadata"]["type"] = "assessment"
    assessment["metadata"]["identifier"]= id

    assessment["_id"]=id;

    r = http_put("#{settings.couchdb}/#{params[:db]}/#{id}",assessment)
    index(params[:db],assessment)

    redirect to("#{settings.base}/#{params[:db]}/assessment/#{id}")
end

get "/:db/assessment/:id" do
    require_logged_in

    assessment = http_get("#{settings.couchdb}/#{params[:db]}/#{params[:id]}")

    assessment["metadata"]["created_date"] = Time.at(assessment["metadata"]["created"]).to_s[0..9]
    assessment["metadata"]["modified_date"] = Time.at(assessment["metadata"]["modified"]).to_s[0..9]

    if assessment["review"] && assessment["review"]["rationale"].length >=1 
      if assessment["review"].has_key?("rewrite") 
        if assessment["review"]["rewrite"] 
          assessment["rationale"] = assessment["review"]["rationale"]
        end
      else
        assessment["rationale"] = assessment["review"]["rationale"]
      end
    end
    if assessment["review"] 
      if assessment["review"]["rationale"].length >=1 
        if assessment["review"].has_key?("rewrite") 
          if assessment["review"]["rewrite"] 
            assessment["rationale"] = assessment["review"]["rationale"]
          end
        else
          assessment["review"]["rewrite"]=true
          assessment["rationale"] = assessment["review"]["rationale"]
        end
      else
          assessment["review"]["rewrite"]=false
      end
    end

    assessment["status-#{assessment["metadata"]["status"]}"] = true

    specie=assessment["taxon"]

    can_edit = assessment["metadata"]["creator"] == session["user"]["name"]
    session[:user]["roles"].each{|r|
      if r["context"].downcase==params[:db].downcase then
        r["roles"].each{|role|
          if role["role"].downcase == "assessor" then
            role["entities"].each {|e|
              if e.downcase == specie["scientificName"].downcase || e.downcase == specie["scientificNameWithoutAuthorship"].downcase || e.downcase == specie["family"].downcase || e.downcase == 'all' then
                can_edit=true;
              end
            }
          end
        }
      end
    }

    can_review = false
    session[:user]["roles"].each{|r|
      if r["context"].downcase==params[:db].downcase then
        r["roles"].each{|role|
          if role["role"].downcase == "evaluator" then
            role["entities"].each {|e|
              if e.downcase == specie["scientificName"].downcase || e.downcase == specie["scientificNameWithoutAuthorship"].downcase || e.downcase == specie["family"].downcase || e.downcase=='all' then
                can_review=true;
              end
            }
          end
        }
      end
    }

    can_see_review = false
    if (assessment["assessor"] == session["user"]["name"] or assessment["evaluator"] == session["user"]["name"]) then
      can_see_review = true
    end

    profile = search(params[:db],"profile","taxon.scientificNameWithoutAuthorship:\"#{assessment["taxon"]["scientificNameWithoutAuthorship"]}\"")[0]

    past = []

    got={}
    http_get("#{ settings.couchdb }/_all_dbs").each {|past_db|
      if past_db[0] != "_" && !past_db.match('_history') && past_db != "public" && past_db != params[:db] then
        past_assessment=  search(past_db,"assessment","taxon.scientificNameWithoutAuthorship:\"#{assessment["taxon"]["scientificNameWithoutAuthorship"]}\"")[0]
        if past_assessment && !past_assessment.nil? && !got[past_assessment["id"]] then
          got[past_assessment["id"]]=true
          past_assessment["past_db"] = past_db
          past_assessment["past_id"] = past_assessment["id"]
          past_assessment["metadata"]["created_date"] = Time.at(past_assessment["metadata"]["created"]).to_s[0..9]
          past_assessment["metadata"]["modified_date"] = Time.at(past_assessment["metadata"]["modified"]).to_s[0..9]
          past_assessment["metadata"]["modified_year"] = Time.at(past_assessment["metadata"]["modified"]).strftime("%Y")
          past_assessment["title"] = past_db.split("_").map(&:capitalize).join(" ")
          past.push(past_assessment)
        end
      end
    }

    past = past.sort_by{|a| a["metadata"]["modified_date"] }


    view :view, {:assessment => assessment, :can_edit=>can_edit, :can_review=>can_review,:db=>params[:db], :profile=>profile, :past=>past, :can_see_review=>can_see_review}
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
    assessment["assessor"] = session[:user]["name"]

    data = JSON.parse(params["data"])
    data["_rev"] = assessment["_rev"]
    data["_id"] = assessment["_id"]
    data["metadata"] = assessment["metadata"]
    data["taxon"] = assessment["taxon"]
    data["profile"] = assessment["profile"]
    data["assessor"] = session[:user]["name"]

    if assessment["review"]
        data["review"] = assessment["review"]
        if assessment["rationale"] != data["rationale"]
          data["review"]["rewrite"]=false
        end
    end

    if assessment["comments"]
        data["comments"] = assessment["comments"]
    end

    r = http_put("#{settings.couchdb}/#{params[:db]}/#{params[:id]}",data)
    index(params[:db],data)

    content_type :json
    JSON.dump(data)
end


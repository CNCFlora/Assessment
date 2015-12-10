
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

    # Get profile
    profile = search(params[:db],"profile","taxon.scientificNameWithoutAuthorship:\"#{assessment["taxon"]["scientificNameWithoutAuthorship"]}\"")[0]

    # Get current taxonomy
    currentTaxon = http_get("#{settings.floradata}/api/v1/specie?scientificName=#{assessment["taxon"]["scientificNameWithoutAuthorship"]}")["result"]
    if currentTaxon.nil? then
      currentTaxon={"not_found"=>true,"synonyms"=>[]}
    elsif currentTaxon["scientificNameWithoutAuthorship"] != assessment['taxon']['scientificNameWithoutAuthorship'] then
      currentTaxon["changed"]=true
    else
      syns = search(params[:db],"taxon","taxonomicStatus:synonym AND acceptedNameUsage:\"#{assessment['taxon']['scientificNameWithoutAuthorship']}\"").map {|s| s["scientificNameWithoutAuthorship"]} .sort().join(",")
      fsyns = currentTaxon["synonyms"].map {|s| s["scientificNameWithoutAuthorship"]} .sort().join(",")
      if syns != fsyns then
        currentTaxon['synonym_changed']=true
      end
    end

    # Get past assessments
    past = []
    got={}
    http_get("#{ settings.couchdb }/_all_dbs").each {|past_db|
      if past_db[0] != "_" && !past_db.match('_history') && past_db != "public" && past_db != params[:db] then
        # Get accepted name
        names = [assessment["taxon"]["scientificNameWithoutAuthorship"]]
        # Get current taxonomy
        if not currentTaxon.nil? then
          names.push(currentTaxon["scientificNameWithoutAuthorship"])
        end
        # Add synonyms already registered in our database
        syns = search(params[:db],"taxon","taxonomicStatus:synonym AND acceptedNameUsage:\"#{assessment['taxon']['scientificNameWithoutAuthorship']}\"").map {|s| s["scientificNameWithoutAuthorship"]}
        # Add new synonyms from FloraData
        fsyns = currentTaxon["synonyms"].map {|s| s["scientificNameWithoutAuthorship"]}
        # Combine arrays
        names = (names | syns | fsyns)
        query = "taxon.scientificNameWithoutAuthorship:\"" + names.join("\" OR taxon.scientificNameWithoutAuthorship:\"") + "\""

        # Get past assessments
        past_assessment=  search(past_db,"assessment", query)[0]
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

    view :view, 
      {
      :assessment => assessment,
      :can_edit=>can_edit,
      :can_review=>can_review,
      :db=>params[:db],
      :profile=>profile, 
      :past=>past, 
      :can_see_review=>can_see_review,
      :currentTaxon=>currentTaxon
    }
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

    # Get current taxonomy
    currentTaxon = http_get("#{settings.floradata}/api/v1/specie?scientificName=#{assessment["taxon"]["scientificNameWithoutAuthorship"]}")["result"]
    if currentTaxon.nil? then
      currentTaxon={"not_found"=>true,"synonyms"=>[]}
    end

    #Get past assessments
    past = []

    got={}
    http_get("#{ settings.couchdb }/_all_dbs").each {|past_db|
      if past_db[0] != "_" && !past_db.match('_history') && past_db != "public" && past_db != params[:db] then
        # Get accepted name
        names = [assessment["taxon"]["scientificNameWithoutAuthorship"]]
        # Get current taxonomy
        if not currentTaxon.nil? then
          names.push(currentTaxon["scientificNameWithoutAuthorship"])
        end
        # Add synonyms already registered in our database
        syns = search(params[:db],"taxon","taxonomicStatus:synonym AND acceptedNameUsage:\"#{assessment['taxon']['scientificNameWithoutAuthorship']}\"").map {|s| s["scientificNameWithoutAuthorship"]}
        # Add new synonyms from FloraData
        fsyns = currentTaxon["synonyms"].map {|s| s["scientificNameWithoutAuthorship"]}
        # Combine arrays
        names = (names | syns | fsyns)
        query = "taxon.scientificNameWithoutAuthorship:\"" + names.join("\" OR taxon.scientificNameWithoutAuthorship:\"") + "\""

        # Get past assessments
        past_assessment=  search(past_db,"assessment", query)[0]
        if past_assessment && !past_assessment.nil? && !got[past_assessment["id"]] then
          got[past_assessment["id"]]=true
          past_assessment["past_db"] = past_db
          past_assessment["past_id"] = past_assessment["id"]
          past_assessment["metadata"]["created_date"] = Time.at(past_assessment["metadata"]["created"]).to_s[0..9]
          past_assessment["metadata"]["modified_date"] = Time.at(past_assessment["metadata"]["modified"]).to_s[0..9]
          past_assessment["metadata"]["modified_year"] = Time.at(past_assessment["metadata"]["modified"]).strftime("%Y")
          past_assessment["title"] = past_db.split("_").map(&:capitalize).join(" ")
          past_string = "<a href=\"#{ settings.base }/#{past_db}/assessment/#{past_assessment["past_id"]}\" class=\"year\">"\
                        "#{past_assessment["metadata"]["modified_year"]} - #{past_assessment["title"]}:</a></ul>"\
                        "<li style=\"padding-left:3em\"><b>#{settings.strings["category"]}:</b> #{past_assessment["category"]}</li>"\
                        "<li style=\"padding-left:3em\"><b>#{settings.strings["criteria"]}:</b> #{past_assessment["criteria"]}</li>"\
                        "</ul>"
          past.push(past_string)
        end
      end
    }
    assessment["past"] = past
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



get "/workflow" do

    species = search("taxon","taxonomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")

    _families = []

    species.each{|spp|
        _families << spp["family"]
    }

    families=[]

    _families.uniq.each{|family|
        families << { "family"=>family,"not_started"=>0, "open"=>0, "review"=>0, "published"=>0, "comments"=>0, "total"=>0 }
    }

    assessments = search("assessment","*")

    assessments.each{ |doc|

        family = doc["taxon"]["family"]
        status = doc["metadata"]["status"]

        element = families.find{ |k| k["family"]==family }
        element[status] += 1
    }

    families.each {|family|
        family["total"]= search("taxon","family:\"#{family["family"]}\" AND taxonomicStatus:\"accepted\" 
                        AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")").length
        family["not_started"] = family["total"] - (family["open"] + family["review"] + family["published"] + family["comments"])
    }

    families = families.sort_by{ |k| k["family"]}

    view :workflow, { :families=>families }
end

get "/workflow/:family" do

    species = search("taxon","taxonomicStatus:\"accepted\" AND taxon.family:\"#{params[:family]}\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")

    family = {
        "scientificName"=>params[:family],
        "status"=>{
            "open"=>{"species"=>[], "total"=>0, "status"=>"open"},
            "review"=>{"species"=>[], "total"=>0, "status"=>"review"},
            "published"=>{"species"=>[], "total"=>0, "status"=>"published"},
            "comments"=>{"species"=>[], "total"=>0, "status"=>"comments"},
            "not_started"=>{"species"=>[], "total"=>0,"status"=>'not_started'}
        },
        "total"=>0
    }

    species.each{ |specie|
        family["total"] += 1
        _specie = search("assessment","scientificNameWithoutAuthorship:\"#{specie["scientificNameWithoutAuthorship"]}\"")[0]
        _specie.nil? ? status = "not_started" : status = _specie["metadata"]["status"]
        family["status"][status]["species"] << specie["scientificNameWithoutAuthorship"]
        family["status"][status]["total"] += 1 
    }

    family["status_vetor"] = family["status"].values
    puts "family[staus] = #{family["status"]}" 
    puts "family[staus].values = #{family["status_vetor"]}" 
    view :workflow_family, {:family=>family}
end

post "/assessment/:id/status/:status" do    
    assessment = settings.conn.get(params[:id])
    contributors = assessment[:metadata][:contributor].split(" ; ")
    contributors = [session[:user][:name]].concat(contributors).uniq()
    assessment[:metadata][:contributor] = contributors.join(" ; ")
    contacts = assessment[:metadata][:contact].split(" ; ")
    contacts = [session[:user][:email]].concat(contributors).uniq()
    assessment[:metadata][:contact] = contributors.join(" ; ")
    assessment[:metadata][:status] = params[:status]
    assessment[:metadata][:modified] = Time.now.to_i

    settings.conn.update(assessment)
    redirect to("/assessment/#{assessment[:_id]}")
end

post "/assessment/:id/change" do
    assessment = settings.conn.get(params[:id])
    assessment[:metadata][:status] = params[:status]
    settings.conn.update(assessment)
    redirect to("/assessment/#{assessment[:_id]}")
end


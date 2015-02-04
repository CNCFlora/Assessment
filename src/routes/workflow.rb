
get "/:db/workflow" do
    require_logged_in

    species = search(params[:db],"taxon","taxonomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")

    _families = []

    species.each{|spp|
        _families << spp["family"]
    }

    families=[]

    _families.uniq.each{|family|
        families << { "family"=>family,"not_started"=>0, "open"=>0, "review"=>0, "published"=>0, "comments"=>0, "total"=>0 }
    }

    assessments = search(params[:db],"assessment","*")

    assessments.each{ |doc|
        family = doc["taxon"]["family"]
        status = doc["metadata"]["status"]

        element = families.find{ |k| k["family"]==family }
        if element then element[status] += 1 end
    }

    families.each {|family|
        family["total"]= search(params[:db],"taxon","family:\"#{family["family"]}\" AND taxonomicStatus:\"accepted\" 
                        AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")").length
        family["not_started"] = family["total"] - (family["open"] + family["review"] + family["published"] + family["comments"])
    }

    families = families.sort_by{ |k| k["family"]}

    view :workflow, { :families=>families, :db=>params[:db] }
end

get "/:db/workflow/:family" do
    require_logged_in

    species = search(params[:db],"taxon","taxonomicStatus:\"accepted\" AND taxon.family:\"#{params[:family]}\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")

    family = {
        "scientificName"=>params[:family],
        "status"=>{
            "not_started"=>{"species"=>[], "total"=>0,"status"=>'not_started'},
            "open"=>{"species"=>[], "total"=>0, "status"=>"open"},
            "review"=>{"species"=>[], "total"=>0, "status"=>"review"},
            "comments"=>{"species"=>[], "total"=>0, "status"=>"comments"},
            "published"=>{"species"=>[], "total"=>0, "status"=>"published"}
        },
        "total"=>0
    }

    species.each{ |specie|
        family["total"] += 1
        _specie = search(params[:db],"assessment","scientificNameWithoutAuthorship:\"#{specie["scientificNameWithoutAuthorship"]}\"")[0]
        _specie.nil? ? status = "not_started" : status = _specie["metadata"]["status"]
        family["status"][status]["species"] << specie["scientificNameWithoutAuthorship"]
        family["status"][status]["total"] += 1 
    }

    family["status_vetor"] = family["status"].values
    view :workflow_family, {:family=>family,:db=>params[:db]}
end

post "/:db/assessment/:id/status/:status" do    
    require_logged_in

    assessment = http_get("#{settings.couchdb}/#{params[:db]}/#{params[:id]}")

    contributors = assessment["metadata"]["contributor"].split(" ; ")
    contributors = [session["user"]["name"]].concat(contributors).uniq()
    assessment["metadata"]["contributor"] = contributors.join(" ; ")
    contacts = assessment["metadata"]["contact"].split(" ; ")
    contacts = [session["user"]["email"]].concat(contributors).uniq()
    assessment["metadata"]["contact"] = contributors.join(" ; ")
    assessment["metadata"]["status"] = params[:status]
    assessment["metadata"]["modified"] = Time.now.to_i

    r = http_put("#{settings.couchdb}/#{params[:db]}/#{params[:id]}",assessment)
    index(params[:db],assessment)

    redirect to("#{settings.base}/#{params[:db]}/assessment/#{params[:id]}")
end

post "/:db/assessment/:id/change" do
    require_logged_in
    assessment = http_get("#{settings.couchdb}/#{params[:db]}/#{params[:id]}")
    assessment['metadata']['status'] = params[:status]
    r = http_put("#{settings.couchdb}/#{params[:db]}/#{params[:id]}",assessment)
    index(params[:db],assessment)
    redirect to("#{settings.base}/#{params[:db]}/assessment/#{assessment[:_id]}")
end


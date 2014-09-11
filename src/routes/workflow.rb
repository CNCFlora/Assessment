
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
        "family"=>params[:family],
        "not_started"=>{"species"=>[], "total"=>0}, 
        "open"=>{"species"=>[], "total"=>0}, 
        "review"=>{"species"=>[], "total"=>0}, 
        "published"=>{"species"=>[], "total"=>0}, 
        "comments"=>{"species"=>[], "total"=>0}, 
        "total"=>{"species"=>[], "total"=>0} 
    }

    species.each{ |specie|        
        _specie = search("assessment","scientificNameWithoutAuthorship:\"#{specie["scientificNameWithoutAuthorship"]}\"")
        if _specie.length == 1
            family[ _specie[0]["metadata"]["status"] ]["species"] << specie["scientificNameWithoutAuthorship"]
            family[ _specie[0]["metadata"]["status"] ]["total"] += 1
        else
            family["not_started"]["species"] << specie["scientificNameWithoutAuthorship"]
            family["not_started"]["total"] += 1
        end
        #puts "x: #{specie}"
        #puts "x: #{specie["taxon"]["scientificNameWithoutAuthorship"]} - #{specie["metadata"]}"
        #family[ specie["metadata"]["status"] ]["species"] << specie["taxon"]["scientificNameWithoutAuthorship"]
        #family[ specie["metadata"]["status"] ]["total"] += 1
    }

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


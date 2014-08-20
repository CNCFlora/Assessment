
get "/workflow" do
    ents=[]
    session[:user]["roles"].each { | role |
        role["entities"].each { | entity |
            ents.push(entity)
        }
    }

    species=[]

    q = "taxonomicStatus:\"accepted\" AND (\"#{ents.join("\" OR \"")}\")"
    search("taxon",q).each {|taxon|
        taxon["assessment"] = search("assessment","\"#{taxon["scientificNameWithoutAuthorship"]}\"")[0]
        taxon["family"].upcase!
        species.push taxon
    }
    
    species.sort { |a,b| a["family"] < b["family"] ? -1 : (a["family"] > b["family"] ? 1 : (a["scientificName"] <=> b["scientificName"])) }

    view :workflow, {:species=>species}
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


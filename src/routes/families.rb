
get "/families" do
    families=[]

    r = search("taxon","taxonomicStatus:\"accepted\"")
    r.each{|taxon|
        families.push taxon["family"]
    }

    view :families, {:families=>families.uniq.sort}
end

get "/family/:family" do
    family = params[:family]
    species= search("taxon","family:\"#{family}\" AND taxonomicStatus:\"accepted\" 
                    AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
                    .sort {|t1,t2| t1["scientificName"] <=> t2["scientificName"] }
    view :species, {:species=>species,:family=>family}
end

get "/specie/:scientificName" do
    specie = search("taxon","scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]
    assessment = search("assessment","taxon.scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]
    if assessment
        redirect to("#{settings.base}/assessment/#{assessment["id"]}")
    else
        view :new, {:specie => specie}
    end
end


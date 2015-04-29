
get "/:db/families" do
    require_logged_in
    families=[]

    r = search(params[:db],"taxon","taxonomicStatus:\"accepted\"")
    r.each{|taxon|
        families.push taxon["family"].upcase
    }

    view :families, {:families=>families.uniq.sort,:db=>params[:db]}
end

get "/:db/family/:family" do
    require_logged_in
    family = params[:family]
    species= search(params[:db],"taxon","family:\"#{family}\" AND taxonomicStatus:\"accepted\" 
                    AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
                    .sort {|t1,t2| t1["scientificName"] <=> t2["scientificName"] }
    view :species, {:species=>species,:family=>family,:db=>params[:db]}
end

get "/:db/specie/:scientificName" do
    require_logged_in
    specie = search(params[:db],"taxon","scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]
    assessment = search(params[:db],"assessment","taxon.scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]
    if assessment
        redirect to("#{settings.base}/#{params[:db]}/assessment/#{assessment["id"]}")
    else
        profile = search(params[:db],"profile","taxon.scientificNameWithoutAuthorship:\"#{params[:scientificName]}\"")[0]
        can_create=false
        session[:user]["roles"].each{|r|
          if r["context"].downcase==params[:db].downcase then
            r["roles"].each{|role|
              if role["role"].downcase == "assessor" then
                role["entities"].each {|e|
                  if e.downcase == specie["scientificName"].downcase || e.downcase == specie["scientificNameWithoutAuthorship"].downcase || e.downcase == specie["family"].downcase then
                    can_create=true;
                  end
                }
              end
            }
          end
        }
        view :new, {:specie => specie,:db=>params[:db],:can_create=>can_create,:profile=>profile}
    end
end


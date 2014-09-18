
get "/assessment/:id/review" do 
    require_logged_in
    assessment = settings.conn.get(params[:id])
    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    if assessment[:review] && assessment[:review][:status] 
        assessment[:review]["status-#{assessment[:review][:status]}"] = true
    end

    if assessment[:review] && assessment[:review][:rationale].length >=1 
        assessment[:rationale] = assessment[:review][:rationale]
    end

    view :review, {:assessment => assessment}
end

post "/assessment/:id/review" do
    require_logged_in
    assessment = settings.conn.get(params[:id])

    assessment[:review] = {:status=>params[:status],:comment=>params[:comment],:rationale=>params[:rationale]}
    assessment[:evaluator] = session[:user]["name"]

    contributors = assessment[:metadata][:contributor].split(" ; ")
    contributors = [session[:user]["name"]].concat(contributors).uniq().select {|c| c != nil && c.length >= 2} 
    assessment[:metadata][:contributor] = contributors.join(" ; ")

    contacts = assessment[:metadata][:contact].split(" ; ")
    contacts = [session[:user]["email"]].concat(contacts).uniq().select {|c| c != nil && c.length >= 2}
    assessment[:metadata][:contact] = contacts.join(" ; ")

    settings.conn.update(assessment)

    redirect to("#{settings.base}/assessment/#{assessment[:_id]}")
end

get "/assessment/:id/comment" do
    require_logged_in
    assessment = settings.conn.get(params[:id])
    assessment[:metadata][:created_date] = Time.at(assessment[:metadata][:created]).to_s[0..9]
    assessment[:metadata][:modified_date] = Time.at(assessment[:metadata][:modified]).to_s[0..9]

    if assessment[:review] && assessment[:review][:rationale].length >=1 
        assessment[:rationale] = assessment[:review][:rationale]
    end

    owner = assessment[:metadata][:creator] == session[:user]["name"]
    view :comments, {:assessment => assessment,:owner=>owner }
end

post "/assessment/:id/comment" do
    require_logged_in
    assessment = settings.conn.get(params[:id])

    if assessment[:comments] == nil 
        assessment[:comments] = []
    end

    assessment[:comments].push({:creator=>session[:user]["name"] ,:contact=>session[:user]["email"] ,:created=>Time.new.to_i ,:comment=>params[:comment]})

    settings.conn.update(assessment)
    redirect to("#{settings.base}/assessment/#{assessment[:_id]}")
end

get "/assessment/:id/comment/:created/delete" do
    require_logged_in
    assessment = settings.conn.get(params[:id])

    assessment[:comments] = assessment[:comments]
                                .select {|c| c[:created] != params[:created].to_i }

    settings.conn.update(assessment)
    redirect to("#{settings.base}/assessment/#{assessment[:_id]}")
end


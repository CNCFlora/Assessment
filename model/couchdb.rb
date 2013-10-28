require 'multi_json'
require 'rest-client'
require 'uri-handler'

class CouchDB

    def initialize(url)
        @url = url
    end

    def _get(url="")
        r = RestClient.get "#{@url}#{url}"
        MultiJson.load(r.to_str, :symbolize_keys => true)
    end

    def _post(data)
        begin
            r = RestClient.post "#{@url}", MultiJson.dump(data), :content_type => :json, :accept => :json
        rescue RestClient::Forbidden => e
            puts e.response.to_str
            r = e.response
        end
        MultiJson.load(r.to_str, :symbolize_keys => true)
    end

    def db()
        _get()
    end

    def create(doc)
        r = _post(doc)
        doc[:_id]  = r[:id]
        doc[:_rev] = r[:rev]
        doc
    end

    def update(doc)
        r = _post(doc)
        doc[:_rev] = r[:rev]
        doc
    end

    def get(id)
        begin
            _get "/#{id.to_uri}"
        rescue RestClient::ResourceNotFound
            nil
        rescue RestClient::BadRequest => e
            puts e.response.to_str
            nil
        end
    end

    def delete(doc)
        r = RestClient.delete "#{@url}/#{doc[:_id]}?rev=#{doc[:_rev]}", :content_type => :json
        nil
    end

    def view(design,view,args={})
        url = "/_design/#{design}/_view/#{view}?"
        if args.has_key?(:key)
            key = MultiJson.dump(args[:key]).to_uri
            url << "&key=#{key}"
        end
        if args.has_key?(:group)
            key = MultiJson.dump(args[:group]).to_uri
            url << "&group=#{key}"
        end
        if args.has_key?(:reduce)
            key = MultiJson.dump(args[:reduce]).to_uri
            url << "&reduce=#{key}"
        end
        _get(url)[:rows]
    end

    def get_all() 
        docs = []
        _get("/_all_docs?_include_docs=true")[:rows].each{ | row | docs << row[:doc ] }
        docs
    end
end

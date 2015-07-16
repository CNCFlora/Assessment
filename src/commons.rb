require 'uri'
require 'json'
require 'net/http'
require 'yaml'

def http_get(uri)
    JSON.parse(Net::HTTP.get(URI(uri)))
end

def http_post(uri,doc)
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)

    if doc.class == Hash
        header = {'Content-Type'=> 'application/json'}
    elsif doc.class == String
        header = {'Content-Type'=> 'application/x-www-form-urlencoded'}
    end

    request = Net::HTTP::Post.new(uri.request_uri, header)

    if doc.class == Hash
        request.body = doc.to_json
    elsif doc.class == String
        request.body = doc
    end

    response = http.request(request)
    JSON.parse(response.body)
end

def http_put(uri,doc) 
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)

    if doc.class == Hash
        header = {'Content-Type'=> 'application/json'}
    elsif doc.class == String
        header = {'Content-Type'=> 'application/x-www-form-urlencoded'}
    end

    request = Net::HTTP::Put.new(uri.request_uri, header)

    if doc.class == Hash
        request.body = doc.to_json
    elsif doc.class == String
        request.body = doc
    end

    response = http.request(request)

    JSON.parse(response.body)
end

def http_delete(uri)
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)
    response = http.request(request)
    JSON.parse(response.body)
end

def search(db,index,query)
    query="scientificName:'Aphelandra longiflora'" unless query != nil && query.length > 0
    query_json={"query"=>{"query_string"=>{"query"=>query}}}
    result = []
    r = http_post("#{settings.elasticsearch}/#{db}/#{index}/_search?size=99999",query_json)
    if r['hits'] && r['hits']['hits'] then
        r['hits']['hits'].each{|hit|
            result.push(hit["_source"])
        }
    else
        puts "search error #{r}"
    end
    result
end

def es_index(db,doc)
  settings = Sinatra::Application.settings
  redoc = doc.clone
  redoc["id"] = doc["_id"]
  redoc["rev"] = doc["_rev"]
  redoc.delete("_id")
  redoc.delete("_rev")
  redoc.delete("_attachments")
  type = doc["metadata"]["type"]
  r = http_post("#{settings.elasticsearch}/#{db}/#{type}/#{URI.encode(redoc["id"])}",redoc)
  if r.has_key?("error")
    puts "index err = #{r}"
  end
end

def index(db,doc)
  es_index(db,doc)
  sleep 1
end

def index_bulk(db,docs)
  docs.each{|doc| es_index(db,doc) }
  sleep 1
end

def setup(file)
    #config_file file

    @config = YAML.load_file(file)[ENV['RACK_ENV'] || 'development']

    @config.each {|ck,cv|
      ENV.each {|ek,ev|
        if cv =~ /\$#{ek}/ then
          @config[ck] = cv.gsub(/\$#{ek}/,ev)
        end
      }
    }

    #ENV.each {|k,v| @config[k]=v }

    if @config["lang"] then
        @config["strings"] = JSON.parse(File.read("src/locales/#{@config["lang"]}.json", :encoding => "BINARY"))
    end

    if defined? settings then
      @config.each {|k,v| set k.to_sym,v }
      set :config, @config

      use Rack::Session::Pool

      set :session_secret, '1flora2'
      set :views, 'src/views'
    end

    puts "@config loaded"
    puts @config

    @config
end


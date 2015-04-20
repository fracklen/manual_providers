require 'net/http'
require 'net/https'
require "open-uri"
class HttpClient

  def perform_get(url, header_params = {})
    uri=URI(url)
    uri.port = Net::HTTP.https_default_port() if uri.scheme=="https"
    request = Net::HTTP::Get.new(uri.request_uri)
    add_header_params(request, header_params)
    JSON.load response(url, request).body
  end


  def perform_get_basic_auth(url, user, pass, header_params = {})
    open(url, http_basic_authentication: [user, pass]) {|f|
      f.read
    }
  end

  def perform_post(url, json)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl=(uri.scheme=="https")
    req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = json
    http.request(req).body
  end


  def perform_put(url, json)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl=(uri.scheme=="https")
    req = Net::HTTP::Put.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = json
    http.request(req).body
  end

  private

    def add_header_params(request, header_params)
      header_params.keys.each do |key|
        request[key] = header_params[key]
      end
    end

    def response(url, req)
      Net::HTTP.start(URI(url).hostname, URI(url).port) do |http|
        http.request(req)
      end
    end

end

require 'net/http'
require_relative 'http_client'

class CouchClient

	def initialize(database_server_url, options = {})
		@database_server_url = database_server_url
		@options = options
	end

  def doc(id, database)
    url = @database_server_url + database + "/#{id}"
    doc = nil
    if(options[:username] && options[:password])
    	doc = JSON.load http_client.perform_get_basic_auth(url, options[:username], options[:password])
    else
    	doc = JSON.load http_client.perform_get(url)
    end
    (doc.has_key?("error") && doc["error"]=="not_found") ? nil : doc
  end

  def not_found?(doc)
  	doc["error"] && doc["error"]  == "not_found"
  end

  def options
  	@options
  end

  private

    def http_client
      @http_client ||= HttpClient.new
    end

end

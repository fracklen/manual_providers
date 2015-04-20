require 'net/http'
require 'csv'
require_relative 'http_client'

class CustomReportClient

	def initialize(username, password, url="http://www.lokalebasen.dk/admin/custom_report/reports")
		@username = username
    @password = password
		@url = url
	end

	def self.custom_report
    reports = {}
    reports["active_providers"] = 39,
    reports["order_enqueries_pr_month"] = 21,
    reports["order_enqueries_pr_day_last_3_months"] = 21,
    reports["provider_active_locations_sum"] = 101,
    reports["enquiries_pr_month"] = 93,
    reports["dk_active_locations"] = 123,
    reports["enquiries_pr_week"] = 128
    reports
  end

  def custom_report(id, query_params = nil)
  	if(query_params)
  		params = query_params.reduce("?"){|acc,qp| "#{acc}&#{qp[:name]}=#{qp[:value]}"}
  	else
  		params = ""
  	end
    client = HttpClient.new
    url = "#{@url}/#{id}.csv#{params}"
    CSV.parse(http_client.perform_get_basic_auth(url, @username, @password).force_encoding('utf-8'))
  end

  private

    def http_client
      @client ||= HttpClient.new
    end

end

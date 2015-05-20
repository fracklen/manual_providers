require 'json'
require 'csv'
require 'dotenv'
require 'rake'
require 'date'
require 'rake/testtask'
require 'rdoc/task'
require 'net/http'
require 'hashdiff'
require './lib/http_client'
require './lib/manual_providers'

namespace :cronjobs do

  Dotenv.load(File.expand_path("../.env",  __FILE__))

  desc "Creates report for se providers synced manually"
  task :se_manual_providers_report do |t|
    report_key = "se_manual_providers"
    hc = HttpClient.new
    report = base_report(t)
    report[:providers] = []
    report[:providers] << sync(report_key, "kungsleden", ManualProviders.kungsleden)
    report[:providers] << sync(report_key, "skanska", ManualProviders.skanska)
    report[:providers] << sync(report_key, "svenska_hus", ManualProviders.svenska_hus)
    report[:providers] << sync(report_key, "tribona", ManualProviders.tribona)
    report[:providers] << sync(report_key, "profi", ManualProviders.profi)
    report[:providers] << sync(report_key, "wilfast", ManualProviders.wilfast)
    report[:providers] << sync(report_key, "areim", ManualProviders.areim)
    report[:end_date] = DateTime.now
    report[:status] = :finished
    report[:details] = "#{report[:providers].length} manual providers handled"
    response = hc.perform_post(report_target_url, JSON.dump(report))
  end

  private

    def sync(database, provider_name, newest)
      begin
        print "Syncing #{provider_name}..."

        provider = couch_doc(provider_name, database)

        res = { provider: provider_name}

        unless(provider)
          provider = {"_id" => provider_name, "locations" => newest, "type" => "provider" }
          report = { date: DateTime.now, added: newest, removed: [], provider: provider_name, type: :report  }
          puts http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(report))
          puts http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(provider))
          res[:action] = :created
          puts "Provider created"
        else
          current = provider["locations"]
          removed = current - newest
          added = newest - current
          if removed.length > 0 || added.length > 0
            report = { date: DateTime.now, added: added, removed: removed, provider: provider_name, type: :report  }
            current_locations = {"_id"=> provider_name, locations: newest, type: :provider, "_rev" => provider["_rev"] }
            puts http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(report))
            puts http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(current_locations))
            res[:action] = :updated
            puts "Provider updated"
          else
            res[:action] = :no_changes
            puts "No changes"
          end
        end
        { ok: res }
      rescue Exception => e
        puts e
        { error: e, provider: provider_name }
      end
    end

    def couch_doc(id, database)
      url = database_server_url + database + "/#{id}"
      doc = JSON.load http_client.perform_get_basic_auth(url, ENV['COUCH_USERNAME'], ENV['COUCH_PASSWORD'])
      (doc.has_key?("error") && doc["error"]=="not_found") ? nil : doc
    end

    def http_client
      @http_client ||= HttpClient.new
    end

    def base_report(task)
      report = {}
      report[:status] = :new
      report[:rake_task] = task
      report[:start_date] = DateTime.now
      report
    end

    def report_target_url
      database_server_url + report_database
    end

    def database_server_url
      ENV['COUCH_DATABASE_SERVER'] + "/"
    end

    def report_database
      ENV['REPORT_DATABASE']
    end

end

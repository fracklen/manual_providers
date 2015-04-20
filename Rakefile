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
require './lib/couch_client'
require './lib/custom_report_client'
require './lib/manual_providers'

namespace :cronjobs do

  Dotenv.load(File.expand_path("../.env",  __FILE__))
  desc "Synchronizes all"
  task :sync_all do
    # se_manual_providers_report
    # enquiries_pr_week
    # provider_active_locations_sum
  end

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

  desc "Registers changes of active locations for all providers"
  task :provider_active_locations_sum do |t|
    dk_url="http://www.lokalebasen.dk/admin/custom_report/reports"
    se_url="http://www.lokalbasen.se/admin/custom_report/reports"
    dk_rep_key = "provider_active_locations_sum"
    handle_provider_active_locations_sum(t,"provider_active_locations_sum", CustomReportClient.custom_report[dk_rep_key],dk_url)
    handle_provider_active_locations_sum(t,"se_provider_active_locations_sum", 12, se_url)
  end

  def handle_provider_active_locations_sum(t, report_key, report_id, url)
    data_target_url = database_server_url + report_key
    report = base_report(t)
    crc = CustomReportClient.new(ENV['LB_USERNAME'], ENV['LB_PASSWORD'], url)
    hc = HttpClient.new
    custom_rep = crc.custom_report(report_id)

    custom_rep[1..custom_rep.length-1].each do |row|
      print '.'
      uuid = row[1]

      total_active = row[3].to_i
      change = { total_active: total_active, created_at: DateTime.now }

      current = couch_client.doc(uuid, report_key)
      if current.nil?
        puts "Creates #{row[2]}"
        entry = {}
        entry[:id] = row[0]
        entry[:uuid] = uuid
        entry[:company_name] = row[2]
        entry[:updated_at] = DateTime.now
        entry["_id"] = uuid
        entry[:changes] = [change]
        hc.perform_post(data_target_url, JSON.dump(entry))
      else
        if(current["changes"].last["total_active"]!=total_active)
          puts "Updates #{row[2]}"
          current["changes"] << change
          current["updated_at"] = DateTime.now
          hc.perform_post(data_target_url, JSON.dump(current))
        else
          puts "No changes #{row[2]}"
        end
      end
    end

    report[:end_date] = DateTime.now
    report[:status] = :finished
    report[:details] = "#{custom_rep.length-1} providers updated"
    response = hc.perform_post(report_target_url, JSON.dump(report))
  end

  desc "Updates enquiries pr week table"
  task :enquiries_pr_week do |t|
    report_key = "enquiries_pr_week"
    data_target_url = database_server_url + report_key
    report = base_report(t)
    custom_rep = custom_report_client.custom_report(CustomReportClient.custom_report[report_key], [{name: "weeks_ago", value:12}])

    updated = 0
    created = 0
    custom_rep[1..custom_rep.length-1].each do |row|
      id = row[0]
      entry = {}
      entry["_id"] = id
      entry["normal"] = row[1].to_i
      entry["extra"] = row[2].to_i
      entry["vip"] = row[3].to_i
      entry["total"] = row[4].to_i

      doc = couch_client.doc(id, report_key)
      if(doc.nil?)
        entry.delete("_rev")
        puts http_client.perform_post(data_target_url, JSON.dump(entry))
        created = created + 1
      elsif(updated?(doc, entry))
        entry["_rev"] = doc["_rev"]
        puts http_client.perform_put(data_target_url+"/#{id}", JSON.dump(entry))
        updated = updated + 1
      else
        # Nothing
      end
    end

    report[:end_date] = DateTime.now
    report[:status] = :finished
    report[:details] = { message: "#{custom_rep.length-1} enquiries retreived", created: created, updated: updated }
    puts report
    response = http_client.perform_post(report_target_url, JSON.dump(report))
  end

  def updated?(doc, entry)
    diff = HashDiff.diff(doc, entry)
    puts diff.inspect if diff.length > 0
    diff.length > 0
  end

  task :enquiries_pr_month do |t|
    report_key = "enquiries_pr_month"
    data_target_url = database_server_url + report_key
    report = base_report(t)
    custom_rep = custom_report_client.custom_report(CustomReportClient.custom_report[report_key])
    custom_rep[1..custom_rep.length-1].each do |row|
      print '.'
      entry = {}
      entry[:month] = row[0]
      entry[:total] = row[1].to_i
      http_client.perform_post(data_target_url, JSON.dump(entry))
    end

    report[:end_date] = DateTime.now
    report[:status] = :finished
    report[:details] = "#{custom_rep.length-1} enquiries updated"
    response = http_client.perform_post(report_target_url, JSON.dump(report))
  end

  desc "Retreives all active locations - used by location_validation"
  task :sync_active_locations do |t|
    report_key = "dk_active_locations"
    report = base_report(t)
    data_target_url = database_server_url + report_key
    custom_rep = custom_report_client.custom_report(CustomReportClient.custom_report[report_key])
    updated = created = 0
    puts "Syncing #{custom_rep.length} locations"
    custom_rep[1..custom_rep.length-1].each_with_index do |row, index|
      location = {}
      location[:id]=row[0]
      location[:uuid]=row[1]
      location[:normalized_yearly_rent_per_m2]=row[2]
      location[:yearly_rent_and_operational_cost]=row[3]
      location[:provider_name]=row[4]
      location[:provider_uuid]=row[5]
      location[:adress]=row[6]
      location[:postal_code]=row[7].strip
      location[:kind]=row[8]
      location[:state]=row[9]
      doc = couch_client.doc(location[:uuid], report_key)
      print index if index % 100 == 0
      location["_id"] = location[:uuid]
      if doc
        location["_rev"] = doc["_rev"]
        updated = updated + 1
        print "U"
      else
        created = created + 1
        print "C"
      end
      http_client.perform_put(data_target_url + "/" + location[:uuid], location.to_json )
    end
    report[:end_date] = DateTime.now
    report[:status] = :finished
    report[:details] = { msg: "#{custom_rep.length-1} active locations", updated: updated, created: created }
    response = http_client.perform_post(report_target_url, JSON.dump(report))

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

    def couch_client
      options = { :username => ENV['COUCH_USERNAME'], :password => ENV['COUCH_PASSWORD']}
      @couch_client ||= CouchClient.new(database_server_url, options)
    end

    def custom_report_client
      @custom_report_client ||= CustomReportClient.new(ENV['LB_USERNAME'], ENV['LB_PASSWORD'])
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

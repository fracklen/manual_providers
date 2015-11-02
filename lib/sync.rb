class Sync
  def sync_all!(task)
    report_key = "se_manual_providers"
    hc = HttpClient.new
    report = base_report(task)
    report[:providers] = []
    report[:providers] << sync(report_key, :kungsleden)
    report[:providers] << sync(report_key, :skanska)
    report[:providers] << sync(report_key, :svenska_hus)
    report[:providers] << sync(report_key, :tribona)
    report[:providers] << sync(report_key, :profi)
    report[:providers] << sync(report_key, :wilfast)
    report[:providers] << sync(report_key, :areim)
    report[:providers] << sync(report_key, :amf)
    report[:end_date] = DateTime.now
    report[:status] = :finished
    report[:details] = "#{report[:providers].length} manual providers handled"
    response = hc.perform_post(report_target_url, JSON.dump(report))
  end

  def sync(database, provider_key)
    logger.info "Syncing #{provider_key}..."
    newest = ManualProviders.send(provider_key)

    provider = couch_doc(provider_key, database)

    res = { provider: provider_key}

    unless(provider)
      provider = {"_id" => provider_key, "locations" => newest, "type" => "provider" }
      report = { date: DateTime.now, added: newest, removed: [], provider: provider_key, type: :report  }
      logger.info http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(report))
      logger.info http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(provider))
      res[:action] = :created
      logger.info "Provider created"
    else
      current = provider["locations"]
      removed = current - newest
      added = newest - current
      if removed.length > 0 || added.length > 0
        report = { date: DateTime.now, added: added, removed: removed, provider: provider_key, type: :report  }
        current_locations = {"_id"=> provider_key, locations: newest, type: :provider, "_rev" => provider["_rev"] }
        logger.info http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(report))
        logger.info http_client.perform_post("#{database_server_url}/#{database}", JSON.dump(current_locations))
        res[:action] = :updated
        logger.info "Provider updated"
      else
        res[:action] = :no_changes
        logger.info "No changes"
      end
    end

    { ok: res }
  rescue Exception => e
    logger.error e
    { error: e.message.force_encoding('utf-8'), provider: provider_key }
  end

  def couch_doc(id, database)
    url = database_server_url + database + "/#{id}"
    doc = JSON.load http_client.perform_get_basic_auth(url, ENV['COUCH_USERNAME'], ENV['COUCH_PASSWORD'])
    (doc.has_key?("error") && doc["error"]=="not_found") ? nil : doc
  rescue => e
    logger.error(e)
    nil
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

  def logger
    if File.directory?('/var/log/manual_providers/')
      @logger ||= Logger.new('/var/log/manual_providers/provider_cronjob.log')
    else
      @logger ||= Logger.new('cronjob.log')
    end
  end
end

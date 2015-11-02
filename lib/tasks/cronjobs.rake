namespace :cronjobs do
  desc "Creates report for se providers synced manually"
  task :se_manual_providers_report do |t|
    sync = Sync.new.sync_all!(task)
  end
end

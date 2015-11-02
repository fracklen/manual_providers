Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN'] if ENV['NO_RAVEN'].nil?
  config.silence_ready = true
end

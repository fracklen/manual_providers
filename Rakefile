require 'json'
require 'csv'
require 'dotenv'
require 'rake'
require 'date'
require 'rake/testtask'
require 'rdoc/task'
require 'net/http'
require 'hashdiff'
require 'logger'
require './lib/http_client'
require './lib/manual_providers'
require './lib/sync'

Dir.glob('lib/tasks/*.rake').each { |r| load r}

Dotenv.load(File.expand_path("../.env",  __FILE__))

task default: ['cronjobs:se_manual_providers_report']

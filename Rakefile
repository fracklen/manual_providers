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
require 'lbunny'
require './lib/http_client'
require './lib/manual_providers'
require './lib/sync'
require './lib/amqp_worker'
require './lib/rabbitmq_client'
require './lib/cron_subscriber_service'

Dir.glob('lib/tasks/*.rake').each { |r| load r}

Dotenv.load(File.expand_path("../.env",  __FILE__))

task default: ['rabbit:run']

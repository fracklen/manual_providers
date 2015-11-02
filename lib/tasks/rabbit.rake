desc 'Long running Rabbit'
namespace :rabbit do
  task :run do
    AmqpWorker.start
  end
end

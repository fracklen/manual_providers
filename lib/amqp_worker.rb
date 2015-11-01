class AmqpWorker
  SLEEP_DELAY = 5 # seconds

  class << self

    def subscribe_jobs
      CronSubscriberService.subscribe
    end

    def start
      AmqpWorker.new.start
    end
  end

  attr_reader :exit

  def initialize
    @exit = false
  end

  def start
    trap('TERM') do
      stop
    end

    trap('INT') do
      stop
    end

    AmqpWorker.subscribe_jobs

    loop do
      break if @exit
      sleep SLEEP_DELAY
    end
  ensure
    RabbitMQClient.close!
  end

  def stop
    @exit = true
  end
end

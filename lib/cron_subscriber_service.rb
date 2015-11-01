class CronSubscriberService
  class << self
    def subscribe
      RabbitMQClient.subscribe(queue_name, routing_key, opts) do |info, _, payload|
        begin
          payload_data = JSON.parse(payload)
          new(payload_data).handle
          RabbitMQClient.channel.ack(info.delivery_tag, false)
        rescue => e
          Raven.capture_exception(e)
        end
      end
    rescue => e
      Raven.capture_exception(e)
    end

    def queue_name
      "se.cron.manual_providers.requests"
    end

    def routing_key
      "se.cron.manual_providers.requested"
    end

    def opts
      {
        manual_ack: true
      }
    end
  end

  attr_reader :data

  def initialize(data)
    @data = data
    @status = 'PENDING'
  end

  def handle
    task.reenable
    task.invoke
    @status = 'SUCCEEDED'
  rescue => e
    @status = 'FAILED'
    Raven.capture_exception(e)
  ensure
    publish_report
  end

  def task
    Rake::Task[data['task_symbol']]
  end

  def report_data
    data.merge(status: @status).to_json
  end

  def options
    {
      routing_key:  report_routing_key,
      type:         "cron.#{@status.downcase}",
      app_id:       "manual_providers",
      persistent:   true,
      content_type: 'application/json',
      timestamp:    Time.zone.now.to_i
    }
  end

  def report_routing_key
    "se.cron.manual_providers.#{@status.downcase}"
  end

  def publish_report
    RabbitMQClient.publish(report_data, options)
  end
end

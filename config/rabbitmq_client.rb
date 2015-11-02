RabbitMQClient = Lbunny::Client.new(
  ENV['RABBITMQ_URL'] || "amqp://guest:guest@localhost:5672"
)

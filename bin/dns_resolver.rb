require 'celluloid/autostart'
require 'cikl/worker/dns/consumer'
require 'cikl/worker/amqp'

#Celluloid.task_class = Celluloid::TaskThread

#Celluloid.logger.level = Logger::WARN

consumer = Cikl::Worker::DNS::Consumer.new
amqp = Cikl::Worker::AMQP.new
amqp.register_consumer(consumer)
running = true
trap(:INT) do
  running = false
end

while running == true
  sleep 0.1
end

amqp.terminate

#!/usr/bin/env ruby
require File.expand_path('../../config/environment', __FILE__)

require 'cikl/worker/dns/config'
require 'cikl/worker/dns/consumer'
require 'cikl/worker/amqp'

#Celluloid.task_class = Celluloid::TaskThread

#Celluloid.logger.level = Logger::WARN

lambda do
  config = Cikl::Worker::DNS::Config.create_config(WorkerEnvironment::APP_ROOT)
  config.use :config_file
  config_file = ARGV.shift
  if config_file
    config_file = File.expand_path(config_file)
    if !File.readable?(config_file)
      raise "Cannot read '#{config_file}'. Perhaps you need to provide an absolute path?"
    end
    config.read(config_file)
  end
  config.resolve!

  consumer = Cikl::Worker::DNS::Consumer.new(config)
  amqp = Cikl::Worker::AMQP.new(config)
  amqp.register_consumer(consumer)
  running = true
  trap(:INT) do
    running = false
  end

  while running == true
    sleep 0.1
  end

  amqp.stop
end.call

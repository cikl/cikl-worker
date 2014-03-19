require 'logger'
module Cikl
  module Worker
    @@logger = ::Logger.new(STDERR)
    def self.logger
      @@logger
    end
    def self.logger=(new_logger)
      @@logger = new_logger
    end

    module Logger
      def error(msg)
        Cikl::Worker.logger.error(msg)
      end
      def warn(msg)
        Cikl::Worker.logger.warn(msg)
      end
      def info(msg)
        Cikl::Worker.logger.info(msg)
      end
      def debug(msg)
        Cikl::Worker.logger.debug(msg)
      end
    end
  end
end


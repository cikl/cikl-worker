module Cikl
  module Worker
    module Base
      module JobResult
        # @return [Array<String>] returns an array of string payloads
        def payloads
          #:nocov:
          raise NotImplementedError.new
          #:nocov:
        end
      end
    end
  end
end

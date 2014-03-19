module Cikl
  module Worker
    module Base
      module JobResult
        # @return [String] returns a string version of the job result.
        def to_payload
          #:nocov:
          raise NotImplementedError.new
          #:nocov:
        end
      end
    end
  end
end

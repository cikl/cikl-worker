module Cikl
  module Worker
    module Base
      class JobResultPayload
        # @return [Hash] a hash version of the payload.
        def to_hash
          return Hash.new
        end

        def ==(other)
          # :nocov:
          raise NotImplementedError.new
          # :nocov:
        end
      end
    end
  end
end

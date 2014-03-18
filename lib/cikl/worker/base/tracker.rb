
module Cikl
  module Worker
    module Base
      class Tracker
        class Entry
          attr_reader :object, :deadline
          def initialize(object, deadline)
            @object = object  
            @deadline = deadline
          end
        end

        # @param [Float] tout The amount of time before the object is pruned 
        #  from our dataset
        def initialize(tout)
          @oids = []
          @oid_entry_map = {}
          @tout = tout
        end

        # returns the number of entries tracked
        def count
          @oid_entry_map.count
        end

        # Prunes objects older than 'cutoff_time'. If a block is given, then
        # each pruned object will be yielded.
        # @param [Time] cutoff_time The time before which object will be considered
        # "old"
        def prune_old_objects(cutoff_time = Time.now)
          cutoff_time = cutoff_time.to_f
          prune_count = 0
          loop do
            break if @oids.empty?
            oid = @oids.first

            entry = @oid_entry_map[oid]

            if entry.nil?
              # The entry has already been removed from our store.
              @oids.shift
              next
            end

            if entry.deadline > cutoff_time
              # We're no longer looking at old objects. Let's stop.
              break
            end

            # Delete the entry
            @oid_entry_map.delete(oid)

            prune_count += 1

            if block_given?
              yield entry.object
            end
          end

          if prune_count > 0
            warn "Pruned #{prune_count}, #{count} remaining"
          end
        end

        def has?(object)
          @oid_entry_map.has_key?(object.object_id)
        end

        def delete(object)
          entry = @oid_entry_map.delete(object.object_id)
          return nil if entry.nil?
          return entry.object
        end

        def add(object)
          if has?(object)
            raise ArgumentError.new("Already tracking object")
          end
          entry = Entry.new(object, Time.now.to_f + @tout)
          oid = object.object_id
          @oids.push(oid)
          @oid_entry_map[oid] = entry
        end
      end
    end
  end
end

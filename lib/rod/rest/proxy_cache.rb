require 'rod/rest/exception'

module Rod
  module Rest
    # Cache used to store proxy objects.
    class ProxyCache
      # Initializes empty cache.
      def initialize(cache_implementation={})
        @cache_implementation = cache_implementation
      end

      # Returns true if the described object is in the cache.
      def has_key?(description)
        check_description(description)
        @cache_implementation[description_signature(description)]
      end

      # Returns the object stored in the cache. Raises CacheMissed exception if
      # the result is nil.
      def [](description)
        check_description(description)
        value = @cache_implementation[description_signature(description)]
        raise CacheMissed.new(missing_entry_message(description)) if value.nil?
      end

      # Store the +object+ in the cache.
      def store(object)
        check_object(object)
        @cache_implementation[description_signature(rod_id: object.rod_id,type: object.type)] = object
      end

      private
      def description_signature(description)
        "#{description[:rod_id]},#{description[:type]}"
      end

      def check_object(object)
        if !object.respond_to?(:rod_id) || !object.respond_to?(:type)
          raise InvalidData.new(invalid_object_message(object))
        end
      end

      def check_description(description)
        if !description.respond_to?(:has_key?) || !description.has_key?(:rod_id) || !description.has_key?(:type)
          raise InvalidData.new(invalid_description_message(description))
        end
      end

      def missing_entry_message(description)
        "No entry for object rod_id:#{description[:rod_id]} type:#{description[:type]}"
      end

      def invalid_object_message(object)
        "The object cannot be stored in the cache: #{object}."
      end

      def invalid_description_message(description)
        "The description of the object is invalid: #{description}."
      end
    end
  end
end

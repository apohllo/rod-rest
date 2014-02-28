require 'rod/rest/exception'

module Rod
  module Rest
    class ProxyFactory
      # Creates new proxy factory based on the +metadata+ and using given web
      # +client+.
      # Options:
      # * proxy_class - the class used to create the resource proxy factories.
      # * cache - used to cache created proxy instances
      def initialize(metadata,client,options={})
        proxy_class = options[:proxy_class] || Proxy
        @cache = options[:cache]
        @proxies = {}
        metadata.each do |resource_metadata|
          @proxies[resource_metadata.name] = proxy_class.new(resource_metadata,client)
        end
      end

      # Build new object-proxy from the hash-like +object_description+.
      def build(object_description)
        return from_cache(object_description) if in_cache?(object_description)
        check_type(object_description[:type])
        @proxies[object_description[:type]].new(object_description)
      end

      private
      def check_type(type)
        raise UnknownResource.new(type) unless @proxies.has_key?(type)
      end

      def from_cache(description)
        @cache[description]
      end

      def in_cache?(description)
        return false if @cache.nil?
        @cache.has_key?(description)
      end
    end
  end
end

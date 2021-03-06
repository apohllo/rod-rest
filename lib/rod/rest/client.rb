require 'active_model/naming'

require 'rod/rest/exception'
require 'rod/rest/naming'

module Rod
  module Rest
    class Client
      include Naming

      # Options:
      # * http_client - library used to talk via HTTP (e.g. Faraday)
      # * parser - parser used to parse the incoming data (JSON by default)
      # * factory - factory class used to build the proxy objects
      # * url_encoder - encoder used to encode URL strings (CGI by default)
      # * metadata - metadata describing the remote database (optional - it is
      #   retrieved via the API if not given; in that case metadata_factory must
      #   be provided).
      # * metadata_factory - factory used to build the metadata (used only if
      #   metadata was not provided).
      # * proxy_cache - used to cache proxied objects. By default it is
      #   ProxyCache. Might be disabled by passing +nil+.
      def initialize(options={})
        @web_client = options.fetch(:http_client)
        @parser = options[:parser] || JSON
        @proxy_factory_class = options[:factory] || ProxyFactory
        @url_encoder = options[:url_encoder] || CGI
        if options.has_key?(:proxy_cache)
          @proxy_cache = options[:proxy_cache]
        else
          @proxy_cache = ProxyCache.new
        end

        @metadata = options[:metadata]
        if @metadata
          configure_with_metadata(@metadata)
        else
          @metadata_factory = options[:metadata_factory] || Metadata
        end
      end

      # Returns the Database metadata.
      def metadata
        return @metadata unless @metadata.nil?
        @metadata = fetch_metadata
        configure_with_metadata(@metadata)
        @metadata
      end

      # Fetch the object from the remote API. The method requires the stub of
      # the object to be proviede, i.e. a hash containing its +rod_id+ and
      # +type+, e.g. {rod_id: 1, type: "Car"}.
      def fetch_object(object_stub)
        check_stub(object_stub)
        check_method(object_stub)
        __send__(primary_finder_method(object_stub[:type]),object_stub[:rod_id])
      end

      # Fetch object related via the association to the +subject+.
      # The association name is +association_name+ and the object returned is
      # the +index+-th element in the collection.
      def fetch_related_object(subject,association_name,index)
        check_subject_and_association(subject,association_name)
        __send__(association_method(subject.type,association_name),subject.rod_id,index)
      end

      # Fetch objects related via the association to the +subject+.
      # The association name is +association_name+ and the objects are the
      # objects indicated by the idices. This might be a range or a comma
      # separated list of indices.
      def fetch_related_objects(subject,association_name,*indices)
        check_subject_and_association(subject,association_name)
        __send__(plural_association_method(subject.type,association_name),subject.rod_id,*indices)
      end

      # Overrided in order to fetch the metadata if it was not provided in the
      # constructor.
      def method_missing(*args)
        unless @metadata.nil?
          super
        end
        @metadata = fetch_metadata
        configure_with_metadata(@metadata)
        self.send(*args)
      end

      # Detailed description of the client.
      def inspect
        "Rod::Rest::Client<port: #{@web_client.port}, host: #{@web_client.host}>"
      end

      # Short description of the client.
      def to_s
        "ROD REST API client"
      end

      private
      def fetch_metadata
        response = @web_client.get(metadata_path())
        if response.status != 200
          raise APIError.new(no_metadata_error())
        end
        @metadata = @metadata_factory.new(description: response.body)
      end

      def configure_with_metadata(metadata)
        define_counters(metadata)
        define_finders(metadata)
        define_relations(metadata)
        @factory = @proxy_factory_class.new(metadata.resources,self,cache: @proxy_cache)
      end

      def define_counters(metadata)
        metadata.resources.each do |resource|
          self.define_singleton_method(count_method(resource)) do
            return_count(count_path(resource))
          end
          resource.plural_associations.each do |association|
            self.define_singleton_method(association_count_method(resource,association.name)) do |id|
              return_count(association_count_path(resource,id,association.name))
            end
          end
        end
      end

      def define_finders(metadata)
        metadata.resources.each do |resource|
          self.define_singleton_method(primary_finder_method(resource)) do |id|
            return_single(primary_resource_finder_path(resource,id))
          end
          self.define_singleton_method(plural_finder_method(resource)) do |*id|
            return_collection(plural_resource_finder_path(resource,id))
          end
          resource.indexed_properties.each do |property|
            self.define_singleton_method(finder_method(resource,property.name)) do |value|
              return_collection(resource_finder_path(resource,property.name,value))
            end
          end
        end
      end

      def define_relations(metadata)
        metadata.resources.each do |resource|
          resource.plural_associations.each do |association|
            self.define_singleton_method(association_method(resource,association.name)) do |id,index|
              return_single(association_path(resource,association.name,id,index))
            end
            self.define_singleton_method(plural_association_method(resource,association.name)) do |id,*indices|
              return_collection(plural_association_path(resource,association.name,id,*indices))
            end
          end
        end
      end

      def return_count(path)
        get_parsed_response(path)[:count]
      end

      def return_single(path)
        @factory.build(get_parsed_response(path))
      end

      def return_collection(path)
        get_parsed_response(path).map{|hash| @factory.build(hash) }
      end

      def get_parsed_response(path)
        result = @web_client.get(path)
        check_status(result,path)
        @parser.parse(result.body,symbolize_names: true)
      end

      def check_status(response,path)
        case response.status
        when 200
          return
        when 404
          raise MissingResource.new(path)
        else
          raise APIError.new(path)
        end
      end

      def check_stub(object_stub)
        unless object_stub.has_key?(:rod_id) && object_stub.has_key?(:type)
          raise APIError.new(invalid_stub_error(object_stub))
        end
      end

      def check_method(object_stub)
        unless self.respond_to?(primary_finder_method(object_stub[:type]))
          raise APIError.new(invalid_method_error(primary_finder_method(object_stub[:type])))
        end
      end

      def check_subject_and_association(subject,association_name)
        unless self.respond_to?(association_method(subject.type,association_name))
          raise APIError.new(invalid_method_error(association_method(subject.type,association_name)))
        end
      end

      def count_path(resource)
        "/#{plural_resource_name(resource)}"
      end

      def primary_resource_finder_path(resource,id)
        "/#{plural_resource_name(resource)}/#{id}"
      end

      def plural_resource_finder_path(resource,*ids)
        "/#{plural_resource_name(resource)}/#{convert_path_elements(*ids)}"
      end

      def resource_finder_path(resource,property_name,value)
        "/#{plural_resource_name(resource)}#{finder_query(property_name,value)}"
      end

      def association_count_path(resource,id,association_name)
        "/#{plural_resource_name(resource)}/#{id}/#{association_name}"
      end

      def association_path(resource,association_name,id,index)
        "/#{plural_resource_name(resource)}/#{id}/#{association_name}/#{index}"
      end

      def plural_association_path(resource,association_name,id,*indices)
        "/#{plural_resource_name(resource)}/#{id}/#{association_name}/#{convert_path_elements(*indices)}"
      end

      def metadata_path
        "/metadata"
      end

      def convert_path_elements(*elements)
        if elements.size == 1 && Range === elements.first
          elements.first.to_s
        else
          elements.join(",")
        end
      end

      def count_method(resource)
        "#{plural_resource_name(resource)}_count"
      end

      def primary_finder_method(resource)
        "find_#{singular_resource_name(resource)}"
      end

      def plural_finder_method(resource)
        "find_#{plural_resource_name(resource)}"
      end

      def finder_method(resource,property_name)
        "find_#{plural_resource_name(resource)}_by_#{property_name}"
      end

      def association_count_method(resource,association_name)
        "#{singular_resource_name(resource)}_#{association_name}_count"
      end

      def association_method(resource,association_name)
        "#{singular_resource_name(resource)}_#{association_name.to_s.singularize}"
      end

      def plural_association_method(resource,association_name)
        "#{singular_resource_name(resource)}_#{association_name.to_s}"
      end

      def finder_query(property_name,value)
        "?#{@url_encoder.escape(property_name)}=#{@url_encoder.escape(value)}"
      end

      def invalid_stub_error(object_stub)
        "The object stub is invalid: #{object_stub}"
      end

      def invalid_method_error(plural_name)
        "The API doesn't have the method '#{plural_name}'"
      end

      def no_metadata_error
        "The API doesn't provide metadata."
      end
    end
  end
end

require 'active_model/naming'

require 'rod/rest/exception'

module Rod
  module Rest
    class Client
      # Options:
      # * http_client - library used to talk via HTTP (e.g. Faraday)
      # * metadata - metadata describing the remote database
      # * parser - parser used to parse the incoming data (JSON by default)
      # * factory - factory used to build the proxy objects
      # * url_encoder - encoder used to encode URL strings (CGI by default)
      def initialize(options={})
        @web_client = options.fetch(:http_client)
        metadata = options.fetch(:metadata)
        @parser = options[:parser] || JSON
        @factory = options[:factory] || ProxyFactory
        @url_encoder = options[:url_encoder] || CGI

        define_counters(metadata)
        define_finders(metadata)
        define_relations(metadata)
      end

      # Fetch the object from the remote API. The method requires the stub of
      # the object to be proviede, i.e. a hash containing its +rod_id+ and
      # +type+, e.g. {rod_id: 1, type: "Car"}.
      def fetch_object(object_stub)
        check_stub(object_stub)
        check_method(object_stub)
        __send__(primary_finder_method_name(object_stub[:type]),object_stub[:rod_id])
      end

      # Fetch object related via the association to the +subject+.
      # The association name is +association_name+ and the object returned is
      # the +index+-th element in the collection.
      def fetch_related_object(subject,association_name,index)
        check_subject_and_association(subject,association_name)
        __send__(association_method_name(subject.type,association_name),subject.rod_id,index)
      end

      private
      def define_counters(metadata)
        metadata.resources.each do |resource|
          self.class.send(:define_method,"#{plural_resource_name(resource)}_count") do
            get_parsed_response(resource_path(resource))[:count]
          end
          resource.plural_associations.each do |association|
            self.class.send(:define_method,association_count_method_name(resource,association.name)) do |id|
              get_parsed_response(association_count_path(resource,id,association.name))[:count]
            end
          end
        end
      end

      def define_finders(metadata)
        metadata.resources.each do |resource|
          self.class.send(:define_method,primary_finder_method_name(resource)) do |id|
            @factory.build(get_parsed_response(primary_resource_finder_path(resource,id)))
          end
          resource.indexed_properties.each do |property|
            self.class.send(:define_method,finder_method_name(resource,property.name)) do |value|
              get_parsed_response(resource_finder_path(resource,property.name,value)).map{|hash| @factory.build(hash) }
            end
          end
        end
      end

      def define_relations(metadata)
        metadata.resources.each do |resource|
          resource.plural_associations.each do |association|
            self.class.send(:define_method,association_method_name(resource,association.name)) do |id,index|
              @factory.build(get_parsed_response(association_path(resource,association.name,id,index)))
            end
          end
        end
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
        unless self.respond_to?(primary_finder_method_name(object_stub[:type]))
          raise APIError.new(invalid_method_error(primary_finder_method_name(object_stub[:type])))
        end
      end

      def check_subject_and_association(subject,association_name)
        unless self.respond_to?(association_method_name(subject.type,association_name))
          raise APIError.new(invalid_method_error(association_method_name(subject.type,association_name)))
        end
      end

      def resource_path(resource)
        "/#{plural_resource_name(resource)}"
      end

      def primary_resource_finder_path(resource,id)
        "/#{plural_resource_name(resource)}/#{id}"
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

      def plural_resource_name(resource)
        singular_resource_name(resource).pluralize
      end

      def singular_resource_name(resource)
        if resource.respond_to?(:name)
          name = resource.name
        else
          name = resource
        end
        name.gsub("::","_").downcase
      end

      def primary_finder_method_name(resource)
        "find_#{singular_resource_name(resource)}"
      end

      def finder_method_name(resource,property_name)
        "find_#{plural_resource_name(resource)}_by_#{property_name}"
      end

      def association_count_method_name(resource,association_name)
        "#{singular_resource_name(resource)}_#{association_name}_count"
      end

      def association_method_name(resource,association_name)
        "#{singular_resource_name(resource)}_#{association_name.singularize}"
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
    end
  end
end

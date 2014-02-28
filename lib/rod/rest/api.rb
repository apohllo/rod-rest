require 'sinatra/base'
require 'rod/rest/naming'

module Rod
  module Rest
    class API < Sinatra::Base
      class << self
        include Naming

        # Build API for a given +resource+.
        # Options:
        # * +:resource_name+ - the name of the resource (resource.name by default)
        # * +:serializer+ - the serializer used to serialize the ROD objects
        #   (instance of JsonSerializer by default)
        def build_api_for(resource,options={})
          serializer = options[:serializer] || JsonSerializer.new
          resource_name = options[:resource_name] || plural_resource_name(resource)

          define_index(resource,resource_name,serializer)
          define_show(resource,resource_name,serializer)

          resource.plural_associations.each do |property|
            define_association_index(resource,resource_name,property,serializer)
            define_association_show(resource,resource_name,property,serializer)
          end
        end

        # Build metadata API for the given +metadata+.
        # Options:
        # * +:serializer+ - the serializer used to serialize the ROD objects
        def build_metadata_api(metadata,options={})
          serializer = options[:serializer] || JSON
          get "/metadata" do
            serializer.dump(metadata)
          end
        end

        # Start the API for the +database+.
        # Options:
        # * +resource_serializer+ - serializer used for resources
        # * +metadata_serializer+ - serializer used for metadata
        # +web_options+ are passed to Sinatra run! method.
        def start_with_database(database,options={},web_options={})
          build_metadata_api(database.metadata,serializer: options[:metadata_serializer])
          database.send(:classes).each do |resource|
            next if database.special_class?(resource)
            build_api_for(resource,serializer: options[:resource_serializer])
          end
          run!(web_options)
        end

        protected
        # GET /cars
        # GET /cars?name=Mercedes
        def define_index(resource,resource_name,serializer)
          get index_path(resource_name) do
            case params.size
            when 0
              respond_with_count(resource,serializer)
            when 1
              index_name, searched_value = params.first
              respond_with_indexed_resource(resource,index_name,searched_value,serializer)
            else
              respond_with_nil(serializer)
            end
          end
        end

        # GET /cars/1
        # GET /cars/1..3
        # GET /cars/1,2,3
        def define_show(resource,resource_name,serializer)
          get show_path(resource_name) do
            respond_with_resource(params[:id],resource,serializer)
          end
        end

        # GET /cars/1/drivers
        def define_association_index(resource,resource_name,property,serializer)
          get association_index_path(resource_name,property.name) do
            respond_with_related_count(resource,property.name,params[:id].to_i,serializer)
          end
        end

        # GET /cars/1/drivers/0
        # GET /cars/1/drivers/0..2
        # GET /cars/1/drivers/0,1,2
        def define_association_show(resource,resource_name,property,serializer)
          get association_show_path(resource_name,property.name) do
            respond_with_related_resource(params[:id].to_i,params[:index],resource,property,serializer)
          end
        end

        def index_path(resource_name)
          "/#{resource_name}"
        end

        def show_path(resource_name)
          "/#{resource_name}/:id"
        end

        def association_index_path(resource_name,property_name)
          "/#{resource_name}/:id/#{property_name}"
        end

        def association_show_path(resource_name,property_name)
          "/#{resource_name}/:id/#{property_name}/:index"
        end
      end

      protected
      def respond_with_resource(id_param,resource,serializer)
        id_or_range = extract_elements(id_param)
        result =
          if Integer === id_or_range
            fetch_one(id_or_range,resource)
          else
            fetch_collection(id_or_range,resource)
          end
        serializer.serialize(result)
      end

      def respond_with_related_resource(id,index_param,resource,property,serializer)
        object = resource.find_by_rod_id(id)
        if object
          index_or_range = extract_elements(index_param)
          result =
            if Integer === index_or_range
              fetch_one_related(index_or_range,object,property)
            else
              fetch_related_collection(index_or_range,object,property)
            end
          serializer.serialize(result)
        else
          respond_with_nil(serializer)
        end
      end

      def respond_with_count(resource,serializer)
        serializer.serialize({count: resource.count})
      end

      def respond_with_related_count(resource,property_name,id,serializer)
        object = resource.find_by_rod_id(id)
        if object
          serializer.serialize({count: object.send("#{property_name}_count") })
        else
          respond_with_nil(serializer)
        end
      end

      def respond_with_indexed_resource(resource,index_name,searched_value,serializer)
        if resource.respond_to?("find_all_by_#{index_name}")
          serializer.serialize(resource.send("find_all_by_#{index_name}",searched_value))
        else
          respond_with_nil(serializer)
        end
      end

      def fetch_collection(ids,resource)
        ids.map{|id| resource.find_by_rod_id(id) }.compact
      end

      def fetch_one(id,resource)
        resource.find_by_rod_id(id) || report_not_found
      end

      def fetch_related_collection(indices,object,property)
        indices.map{|index| object.send(property.name)[index] }.compact
      end

      def fetch_one_related(index,object,property)
        object.send(property.name)[index] || report_not_found
      end

      def extract_elements(id)
        case id
        when /^(\d+)\.\.(\d+)/
          ($~[1].to_i..$~[2].to_i)
        when /,/
          id.split(",").map(&:to_i)
        else
          id.to_i
        end
      end

      def report_not_found
        status 404
        nil
      end

      def respond_with_nil(serializer)
        report_not_found
        serializer.serialize(nil)
      end
    end
  end
end

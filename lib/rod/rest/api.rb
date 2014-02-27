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
          get "/#{resource_name}" do
            if params.empty?
              serializer.serialize({count: resource.count})
            elsif params.size == 1
              name, value = params.first
              if resource.respond_to?("find_all_by_#{name}")
                serializer.serialize(resource.send("find_all_by_#{name}",value))
              else
                report_not_found
                serializer.serialize(nil)
              end
            else
              report_not_found
              serializer.serialize(nil)
            end
          end

          get "/#{resource_name}/:id" do
            fetch_resource(params[:id],resource,serializer)
          end

          resource.plural_associations.each do |property|
            get "/#{resource_name}/:id/#{property.name}" do
              object = resource.find_by_rod_id(params[:id].to_i)
              if object
                serializer.serialize({count: object.send("#{property.name}_count") })
              else
                report_not_found
                serializer.serialize(nil)
              end
            end

            get "/#{resource_name}/:id/#{property.name}/:index" do
              fetch_related_resource(params[:id],params[:index],resource,property,serializer)
            end
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
      end

      private
      def fetch_resource(id_param,resource,serializer)
        id = extract_elements(id_param)
        result =
          if Integer === id
            fetch_one(id,resource)
          else
            fetch_collection(id,resource)
          end
        serializer.serialize(result)
      end

      def fetch_related_resource(id_param,index_param,resource,property,serializer)
        object = resource.find_by_rod_id(id_param.to_i)
        result =
          if object
            index = extract_elements(index_param)
            if Integer === index
              fetch_one_related(index,object,property)
            else
              fetch_related_collection(index,object,property)
            end
          else
            report_not_found
          end
        serializer.serialize(result)
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
    end
  end
end

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
                status 404
                serializer.serialize(nil)
              end
            else
              status 404
              serializer.serialize(nil)
            end
          end

          get "/#{resource_name}/:id" do
            object = resource.find_by_rod_id(params[:id].to_i)
            if object
              serializer.serialize(object)
            else
              status 404
              serializer.serialize(nil)
            end
          end

          resource.plural_associations.each do |property|
            get "/#{resource_name}/:id/#{property.name}" do
              object = resource.find_by_rod_id(params[:id].to_i)
              if object
                serializer.serialize({count: object.send("#{property.name}_count") })
              else
                status 404
                serializer.serialize(nil)
              end
            end

            get "/#{resource_name}/:id/#{property.name}/:index" do
              object = resource.find_by_rod_id(params[:id].to_i)
              if object
                related_object = object.send(property.name)[params[:index].to_i]
                if related_object
                  serializer.serialize(related_object)
                else
                  status 404
                  serializer.serialize(nil)
                end
              else
                status 404
                serializer.serialize(nil)
              end
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
    end
  end
end

require 'sinatra/base'

module Rod
  module Rest
    class API < Sinatra::Base
      # Build API for a given +resource+.
      # Options:
      # * +:resource_name+ - the name of the resource (resource.name by default)
      # * +:serializer+ - the serializer used to serialize the ROD objects
      #   (instance of JsonSerializer by default)
      def self.build_api_for(resource,options={})
        serializer = options[:serializer] || JsonSerializer.new
        resource_name = options[:resource_name] || resource.name
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
    end
  end
end

require 'sinatra/base'

module Rod
  module Rest
    class API < Sinatra::Base
      def self.build_api_for(resource,resource_name)
        get "/#{resource_name}" do
          if params.empty?
            {count: resource.count}.to_json
          elsif params.size == 1
            name, value = params.first
            if resource.respond_to?("find_all_by_#{name}")
              resource.send("find_all_by_#{name}",value).to_json
            else
              status 404
              nil.to_json
            end
          else
            status 404
            nil.to_json
          end
        end

        get "/#{resource_name}/:id" do
          object = resource.find_by_rod_id(params[:id].to_i)
          if object
            object.to_json
          else
            status 404
            nil.to_json
          end
        end

        resource.plural_associations.each do |property|
          get "/#{resource_name}/:id/#{property.name}" do
            object = resource.find_by_rod_id(params[:id].to_i)
            if object
              {count: object.send("#{property.name}_count") }.to_json
            else
              status 404
              nil.to_json
            end
          end

          get "/#{resource_name}/:id/#{property.name}/:index" do
            object = resource.find_by_rod_id(params[:id].to_i)
            if object
              related_object = object.send(property.name)[params[:index].to_i]
              if related_object
                related_object.to_json
              else
                status 404
                nil.to_json
              end
            else
              status 404
              nil.to_json
            end
          end
        end
      end
    end
  end
end

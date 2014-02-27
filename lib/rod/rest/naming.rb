require 'active_model/naming'

module Rod
  module Rest
    module Naming
      def plural_resource_name(resource)
        singular_resource_name(resource).pluralize
      end

      def singular_resource_name(resource)
        if resource.respond_to?(:name)
          name = resource.name
        else
          name = resource.to_s
        end
        name.gsub("::","_").downcase
      end
    end
  end
end

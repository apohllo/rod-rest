require 'json'

module Rod
  module Rest
    class JsonSerializer
      # Serialize given Rod +object+ to JSON.
      # The serialized object looks as follows:
      # {
      #   rod_id: 1,                            # required +rod_id+
      #   type: "Car",                          # required +type+
      #   name: "Mercedes 300",                 # field value
      #   owner: { rod_id: 1, type: "Person" }  # singular association value
      #   drivers: { count: 3 }                 # plural association value
      # }
      def serialize(object)
        result = { rod_id: object.rod_id, type: object.type }
        resource = object.class
        resource.fields.each do |field|
          result[field.name] = object.send(field.name)
        end
        resource.singular_associations.each do |association|
          associated = object.send(association.name)
          if associated
            result[association.name] = { rod_id: associated.rod_id, type: associated.type }
          else
            result[association.name] = nil
          end
        end
        resource.plural_associations.each do |association|
          result[association.name] = { count: object.send(association.name).size }
        end
        result.to_json
      end
    end
  end
end

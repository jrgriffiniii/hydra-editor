module HydraEditor
  class FieldMetadataService
    # If the field is a reflection, delegate to the reflection.
    # If the field is a property, delegate to the property.
    # Otherwise return false
    def self.multiple?(model_class, field)
      if model_class.respond_to?(:schema)
        # For Valkyrie schemata
        model_class.schema.key?(field) && model_class.schema[field].meta[:ordered]
      elsif model_class.respond_to?(:reflect_on_association)
        # For ActiveFedora reflections
        if reflection = model_class.reflect_on_association(field)
          reflection.collection?
        elsif model_class.attribute_names.include?(field.to_s)
          model_class.multiple?(field)
        else
          false
        end
      elsif model_class.respond_to?(:reflections)
        # For ActiveRecord reflections
        model_class.reflections.key?(field.to_s)
      else
        # The ORM is not supported
        false
      end
    end
  end
end

class HydraEditor::ControllerResource < CanCan::ControllerResource
  def find_resource
    query_service.find_by(id: id_param)
  end

  def resource_class
    raise HydraEditor::InvalidType, 'Lost the type' unless has_valid_type?
    type_param.constantize
  end

  def has_valid_type?
    HydraEditor.valid_model? type_param
  end

  def type_param
    @params[:type]
  end

  private

    class QueryServiceAdapter
      def self.adapter_class(orm_class)
        module_namespace = "HydraEditor::ControllerResource"
        adapter_name = "#{module_namespace}::#{orm_class.name.split('::').first}QueryAdapter"
        adapter_name.constantize
      end

      def self.registered?(orm_class)
        adapter_class(orm_class)
        true
      rescue NameError
        false
      end

      def self.build(orm_class:)
        if registered?(orm_class)
          adapter_class(orm_class).new(orm_class: orm_class)
        else
          new(orm_class: orm_class)
        end
      end

      def initialize(orm_class:)
        @orm_class = orm_class
      end

      def find_by(id:)
        @orm_class.find_by(id: id)
      end
    end

    class ActiveFedoraQueryAdapter < QueryServiceAdapter
      def find_by(id:)
        @orm_class.find(id)
      end
    end

    def orm_module_name
      HydraEditor.config[:module]
    end

    def orm_module
      begin
        orm_module_name.constantize
      rescue
        Rails.logger.error "Failed to load the ORM: #{orm_module_name}.  Using ActiveFedora as the default."
        ActiveFedora::Base
      end
    end

    def orm_class
      case orm_module.name
      when 'Valkyrie'
        Valkyrie.config.metadata_adapter.query_service
      when 'ActiveFedora'
        ActiveFedora::Base
      else
        Rails.logger.warn "The ORM #{orm_module_name} is not supported.  Using ActiveFedora as the default."
        ActiveFedora::Base
      end
    end

    def query_service
      @query_service ||= QueryServiceAdapter.build(orm_class: orm_class)
    end
end

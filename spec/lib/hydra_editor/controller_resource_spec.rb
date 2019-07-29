require 'spec_helper'
require 'pry-byebug'

describe HydraEditor::ControllerResource do
  subject(:controller_resource) { described_class.new(controller) }
  let(:controller) { instance_double(ActionController::Base) }

  before do
    allow(controller).to receive(:params).and_return(id: 'test-id')
  end

  describe '#find_resource' do
    context 'when the Valkyrie ORM is available' do
      let(:query_service) { double }
      let(:metadata_adapter) { double }
      let(:config) { double }
      let(:valkyrie) do
        class_double('Valkyrie').as_stubbed_const(transfer_nested_constants: true)
      end

      before do
        allow(query_service).to receive(:name).and_return('Valkyrie::Persistence::Postgres::QueryService')
        allow(query_service).to receive(:find_by)
        allow(metadata_adapter).to receive(:query_service).and_return(query_service)
        allow(config).to receive(:metadata_adapter).and_return(metadata_adapter)
        allow(valkyrie).to receive(:config).and_return(config)
        controller_resource.find_resource
      end

      it 'attempts to query for the resource using Valkyrie' do
        expect(query_service).to have_received(:find_by)
      end
    end

    context 'when the ActiveFedora ORM is available' do
      let(:active_fedora) do
        class_double('ActiveFedora::Base').as_stubbed_const(transfer_nested_constants: true)
      end

      before do
        allow(active_fedora).to receive(:find)
      end

      it 'attempts to query for the resource using ActiveFedora' do
        controller_resource.find_resource
        expect(active_fedora).to have_received(:find)
      end
    end

    it 'attempts to query for the resource using ActiveRecord' do
      allow(ActiveRecord::Base).to receive(:find_by)
      Object.send(:remove_const, :Valkyrie) if defined?(Valkyrie)
      Object.send(:remove_const, :ActiveFedora) if defined?(ActiveFedora)
      controller_resource.find_resource
      expect(ActiveRecord::Base).to have_received(:find_by).at_least(:once)
    end
  end
end

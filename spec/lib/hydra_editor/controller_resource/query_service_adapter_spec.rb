require 'spec_helper'

describe HydraEditor::ControllerResource::QueryServiceAdapter do
  describe ".adapter_class" do
    let(:orm_class) { ActiveFedora }

    before do
      # class ActiveFedora; end unless defined?(ActiveFedora)
      class ActiveFedora; end
    end

    after do
      Object.send(:remove_const, :ActiveFedora)
    end

    it "builds the class for the query service adapter" do
      adapter = described_class.adapter_class(orm_class)
      expect(adapter).to eq HydraEditor::ControllerResource::ActiveFedoraQueryAdapter
    end
  end

  describe ".registered?" do
    let(:orm_class) { ActiveFedora }

    it "determines whether or not an ORM class has a defined QueryService adapter" do
      expect(described_class.registered?(orm_class)).to be true
      expect(described_class.registered?(DateTime)).to be false
    end
  end

  describe ".build" do
    let(:orm_class) { ActiveFedora }

    it "constructs an adapter for an ORM class" do
      adapter = described_class.build(orm_class)
      expect(adapter).to be_a HydraEditor::ControllerResource::ActiveFedoraQueryAdapter
    end

    context "when the ORM class is not supported" do
      let(:orm_class) { DateTime }

      it "constructs the generic adapter" do
        adapter = described_class.build(orm_class)
        expect(adapter).to be_a described_class
      end
    end
  end

  describe ".find_by" do
    let(:active_record) { class_double(ActiveRecord::Base) }
    let(:adapter) { described_class.new(orm_class: active_record) }

    before do
      allow(active_record).to receive(:find_by)
      adapter.find_by(id: 'foo')
    end

    it "delegates to the #find_by method" do
      expect(active_record).to have_received(:find_by).with(id: 'foo')
    end
  end
end

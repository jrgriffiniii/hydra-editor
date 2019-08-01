RSpec.configure do |config|
  config.before(:all) do
    # For stubbing the API for ActiveFedora models
    class TestFedoraModel

      def self.unique?(field); end
      def self.reflect_on_association(field); end
      def self.terms; end

      def initialize(**args); end
      def title; end
      def creator; end
      def creator=(values); end
      def isPartOf; end
      def new_record?; end
      def persisted?; end
      def model_name
        ActiveModel::Name.new(self.class)
      end
      def save; end
      def id; end
      def attributes=(args); end
      def attributes
        {}
      end
    end

    class TestFedoraModelForm
      include HydraEditor::Form

      def title; end
      def description; end
      def creator; end
      def id; end
    end
  end

  config.after(:all) do
    Object.send(:remove_const, :TestFedoraModelForm)
    Object.send(:remove_const, :TestFedoraModel)
  end

  config.before(:each) do |example|
    if example.metadata[:active_fedora_stubbed]
      allow(form).to receive(:description).and_return([''])
      allow(form).to receive(:title).and_return(['My title'])
      allow(form).to receive(:creator).and_return(['My title'])
      allow(form).to receive(:persisted?).and_return(true)
      allow(form).to receive(:id).and_return('test-id')
      allow(form).to receive(:to_s).and_return('test-id')
      allow(form).to receive(:model_name).and_return(ActiveModel::Name.new(TestFedoraModel))
      allow(form).to receive(:to_key).and_return(['test-id'])
      allow(form).to receive(:terms).and_return([:title, :creator])
      allow(form).to receive(:multiple?).and_return(true)
      allow(form).to receive(:required?).and_return(true)

      allow(form_class).to receive(:model_attributes)
      allow(form_class).to receive(:terms).and_return([:title, :creator])
      allow(form_class).to receive(:new).and_return(form)

      allow(model_class).to receive(:name).and_return('TestFedoraModel')
      allow(model_class).to receive(:new).and_return(object)
      allow(model_class).to receive(:unique?).and_return(false)
      allow(model_class).to receive(:terms).and_return([:title, :creator])

      allow(object).to receive(:save).and_return(true)
      allow(object).to receive(:new_record?).and_return(false)
      allow(object).to receive(:persisted?).and_return(true)
      allow(object).to receive(:model_name).and_return(ActiveModel::Name.new(TestFedoraModel))
      allow(object).to receive(:attributes=)
      allow(object).to receive(:id).and_return('test-id')
      allow(object).to receive(:to_s).and_return('test-id')
      allow(object).to receive(:title).and_return(['My title'])
      allow(object).to receive(:isPartOf).and_return([])
      allow(object).to receive(:creator=)
      allow(object).to receive(:creator).and_return(['Fleece Vest'])
      allow(object).to receive(:class).and_return(model_class)
    end
  end
end

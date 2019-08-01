require 'spec_helper'
require 'pry-byebug'

describe MultiValueInput, type: :input do
  before(:all) do
    class Foo < ActiveRecord::Base
      # property :bar, predicate: ::RDF::URI('http://example.com/bar')
      attr_accessor :bar

      def double_bar
        bar.map { |b| b + b }
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :Foo)
  end

  let(:bar) { ['bar1', 'bar2'] }
  let(:double_bar) { ['bar1', 'bar2'].map { |b| b + b } }
  let(:foo) { instance_double(Foo, bar: bar) }

  before do
    allow(foo).to receive(:model_name).and_return(ActiveModel::Name.new(Foo))
    allow(foo).to receive(:to_key).and_return(['test-id'])
    allow(foo).to receive(:double_bar).and_return(double_bar)
    allow(foo).to receive(:bar).and_return(bar)
  end

  context 'when provided an Array for an attribute' do

    context "for values from a property on the object" do
      subject(:multi_value_input) { input_for(foo, :bar, as: :multi_value, required: true) }

      it 'renders multi-value' do
        # For handling older releases of SimpleForm
        expect(multi_value_input).to have_selector('.form-group.foo_bar.multi_value label.required[for=foo_bar]', text: /(\*\s)?Bar(\s\*)?/)
        expect(multi_value_input).to have_selector('.form-group.foo_bar.multi_value ul.listing li input.foo_bar', count: 3)
      end
    end

    context 'for values from a method on the object' do
      subject(:multi_value_input) { input_for(foo, :double_bar, as: :multi_value) }

      # For handling older releases of SimpleForm
      it 'renders multi-value' do
        expect(multi_value_input).to have_selector('.form-group.foo_double_bar.multi_value ul.listing li input.foo_double_bar', count: 3)
      end
    end
  end

  context 'when provided a nil value for an attribute' do
    subject(:multi_value_input) do
      input_for(foo, :bar, as: :multi_value, required: true)
    end

    before do
      allow(foo).to receive(:bar).and_return([])
    end

    it 'renders multi-value given a nil object' do
      expect(multi_value_input).to have_selector('.form-group.foo_bar.multi_value label.required[for=foo_bar]', text: /(\*\s)?Bar(\s\*)?/)
      expect(multi_value_input).to have_selector('.form-group.foo_bar.multi_value ul.listing li input.foo_bar')
    end
  end

  describe '#build_field' do
    let(:multi_value_input) { described_class.new(builder, :bar, nil, :multi_value, {}) }
    let(:builder) { double('builder', object: foo, object_name: 'foo') }
    before do
      allow(builder).to receive(:text_field)
      allow(multi_value_input).to receive(:build_field)
    end

    it 'renders multi-value' do
      multi_value_input.input({})
      expect(multi_value_input).to have_received(:build_field).with('bar1', Integer)
      expect(multi_value_input).to have_received(:build_field).with('bar2', Integer)
      expect(multi_value_input).to have_received(:build_field).with('', 2)
    end
  end
end

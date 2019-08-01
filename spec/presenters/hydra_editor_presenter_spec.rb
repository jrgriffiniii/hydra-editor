require 'spec_helper'
require 'pry-byebug'

describe Hydra::Presenter do
  let(:model_class) { TestModel }
  let(:object) { instance_double(model_class, title: ['foo', 'bar'], creator: 'baz') }
  let(:presenter) { TestPresenter.new(object) }

  before(:all) do
    # For stubbing the API for ActiveRecord models
    class Contributor < ActiveRecord::Base; end

    class Publisher < ActiveRecord::Base; end

    class TestModel < ActiveRecord::Base
      has_and_belongs_to_many :contributors
      belongs_to :publisher

      # This needs to change
      def self.unique?(field); end
      def title; end
      def creator; end
      # This needs to change
      def new_record?; end
    end

    # For stubbing the API for ActiveFedora models
    class TestFedoraModel

      def self.unique?(field); end
      def self.reflect_on_association(field); end
      def self.terms; end
      def title; end
      def creator; end
      def new_record?; end
      def persisted?; end
      def model_name; end
    end

    class TestPresenter
      include Hydra::Presenter
      # Terms is the list of fields displayed by app/views/generic_files/_show_descriptions.html.erb
      self.terms = [:title, :creator]

      # Depositor and permissions are not displayed in app/views/generic_files/_show_descriptions.html.erb
      # so don't include them in `terms'.
      delegate :depositor, :permissions, to: :model
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestPresenter)
    Object.send(:remove_const, :TestFedoraModel)
    Object.send(:remove_const, :TestModel)
  end

  before do
    TestPresenter.model_class = model_class
    allow(model_class).to receive(:unique?).and_return(false)
    allow(model_class).to receive(:terms).and_return([:title, :creator])
    allow(object).to receive(:new_record?).and_return(false)
    allow(object).to receive(:persisted?).and_return(true)
    allow(object).to receive(:model_name).and_return('TestModel')
  end

  describe 'class methods' do
    subject { TestPresenter.model_name }
    it { is_expected.to eq 'TestModel' }
  end

  describe '#model_name' do
    subject { presenter.model_name }
    it { is_expected.to eq 'TestModel' }
  end

  describe '#terms' do
    subject { presenter.terms }
    let(:model_class) { TestFedoraModel }

    it { is_expected.to eq [:title, :creator] }
  end

  describe 'new_record?' do
    subject { presenter.new_record? }

    before do
      allow(object).to receive(:new_record?).and_return(true)
    end

    it { is_expected.to be true }
  end

  describe 'persisted?' do
    subject { presenter.persisted? }

    before do
      allow(object).to receive(:persisted?).and_return(false)
    end

    it { is_expected.to be false }
  end

  describe 'the term accessors' do
    before do
      allow(object).to receive(:[]).with(:title).and_return(['foo', 'bar'])
      allow(object).to receive(:[]).with(:creator).and_return('baz')
    end

    it 'has the accessors' do
      expect(presenter.title).to match_array ['foo', 'bar']
      expect(presenter.creator).to eq 'baz'
    end

    it 'has the hash accessors' do
      expect(presenter[:title]).to match_array ['foo', 'bar']
      expect(presenter[:creator]).to eq 'baz'
    end
  end

  context 'when a presenter has a method' do
    before do
      TestPresenter.class_eval do
        def count
          7
        end

        self.terms = [:count]
      end
    end

    it "isn't overridden by setting terms" do
      expect(presenter.count).to eq 7
    end
  end

  describe 'multiple?' do
    describe 'instance method' do
      subject { presenter.multiple?(field) }

      context 'for a multivalue string' do
        let(:model_class) { TestFedoraModel }
        let(:object) { model_class.new }
        let(:presenter) { TestPresenter.new(object) }
        let(:reflection) { double }
        before do
          allow(reflection).to receive(:collection?).and_return(true)
          allow(model_class).to receive(:reflect_on_association).with(field).and_return(reflection)
        end
        let(:field) { :title }
        it { is_expected.to be true }
      end

      context 'for a single value string' do
        let(:field) { :creator }
        it { is_expected.to be false }
      end

      context 'for a multivalue association' do
        let(:field) { :contributors }
        let(:model_class) { TestFedoraModel }
        let(:object) { model_class.new }
        let(:presenter) { TestPresenter.new(object) }
        let(:reflection) { double }
        let(:field) { :title }
        before do
          allow(reflection).to receive(:collection?).and_return(true)
          allow(model_class).to receive(:reflect_on_association).with(field).and_return(reflection)
        end

        it { is_expected.to be true }
      end

      context 'for a single value association' do
        let(:field) { :publisher }
        it { is_expected.to be false }
      end

      context 'with anything else' do
        let(:field) { :visibility }
        it { is_expected.to be false }
      end
    end

    describe 'class method' do
      before { allow(Deprecation).to receive(:warn) }
      subject { TestPresenter.multiple?(field) }

      context 'for a multivalue string' do
        let(:model_class) { TestFedoraModel }
        let(:object) { model_class.new }
        let(:presenter) { TestPresenter.new(object) }
        let(:reflection) { double }
        let(:field) { :title }
        before do
          allow(reflection).to receive(:collection?).and_return(true)
          allow(model_class).to receive(:reflect_on_association).with(field).and_return(reflection)
        end
        it { is_expected.to be true }
      end

      context 'for a single value string' do
        let(:field) { :creator }
        it { is_expected.to be false }
      end

      context 'for a multivalue association' do
        let(:field) { :contributors }
        it { is_expected.to be true }
      end

      context 'for a single value association' do
        let(:field) { :publisher }
        it { is_expected.to be false }
      end
    end
  end

  describe 'unique?' do
    before { allow(Deprecation).to receive(:warn) }
    subject { TestPresenter.unique?(field) }

    context 'for a multivalue string' do
      let(:field) { :title }
      it { is_expected.to be false }
    end

    context 'for a single value string' do
      before do
        allow(model_class).to receive(:unique?).with(field).and_return(true)
      end

      let(:field) { :creator }
      it { is_expected.to be true }
    end

    context 'for a multivalue association' do
      let(:field) { :contributors }
      it { is_expected.to be false }
    end

    context 'for a single value association' do
      let(:field) { :publisher }
      it { is_expected.to be true }
    end
  end
end

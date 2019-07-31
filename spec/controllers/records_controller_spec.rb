require 'spec_helper'
require 'pry-byebug'

describe RecordsController do
  routes { HydraEditor::Engine.routes }

  before(:all) do
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
    end
  end
  let(:model_class) { TestFedoraModel }
  let(:object) { instance_double(TestFedoraModel) }
  let(:form_class) { class_double(TestFedoraModelForm).as_stubbed_const(transfer_nested_constants: true) }
  let(:form) { instance_double(TestFedoraModelForm) }

  after(:all) do
    Object.send(:remove_const, :TestFedoraModelForm)
    Object.send(:remove_const, :TestFedoraModel)
  end

  before do
    allow(form).to receive(:description).and_return([''])
    allow(form).to receive(:title).and_return(['My title'])
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

    HydraEditor.models = [model_class.name, 'Pdf']
  end

  describe 'an admin' do
    let(:user) { FactoryBot.create(:admin) }
    before do
      sign_in user
    end
    describe 'who goes to the new page' do
      it 'renders the template for choosing a format type' do
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:choose_type)
      end
      it 'renders the template for a new audio work' do
        get :new, params: { type: model_class.name }
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end

    describe 'creating a new record' do
      let(:stub_audio) { object }

      before do
        allow(stub_audio).to receive(:persisted?).and_return(true)
        # allow(Audio).to receive(:new).and_return(stub_audio)
      end

      context 'when save is successful' do
        before do
          allow(stub_audio).to receive(:save).and_return(true)
        end

        it 'saves the audio work with a title' do
          post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }
          expect(response).to redirect_to("/catalog/#{assigns[:record].id}")
          expect(assigns[:record].title).to eq ['My title']
        end

        it "does not set attributes that aren't listed in terms_for_editing" do
          # params[:audio][:collection_id] would be a good test, but that doesn't work in ActiveFedora 6.7
          post :create, params: { type: model_class.name, model_class.name.underscore => { isPartOf: 'my collection' } }
          expect(response).to redirect_to("/catalog/#{assigns[:record].id}")
          expect(assigns[:record].isPartOf).to eq []
        end

        it 'is successful with json' do
          post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }, format: :json
          expect(response.status).to eq 201
        end

        describe 'when the user has access to create only some classes' do
          before do
            controller.current_ability.cannot :create, ActiveFedora::Base
            controller.current_ability.can :create, model_class
          end
          it 'permits users to create works with the authorized format types' do
            post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }
            expect(response).to redirect_to("/catalog/#{assigns[:record].id}")
            expect(assigns[:record].title).to eq ['My title']
          end
        end

        describe 'when set_attributes is overloaded' do
          controller(described_class) do
            def set_attributes
              super
              @record.creator = ['Fleece Vest']
            end
          end
          # since this is using an an anonymous class, we have to stub
          before do
            allow(controller).to receive(:resource_instance_name).and_return('record')
          end

          it 'runs set_attributes' do
            post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }
            expect(response).to redirect_to("/catalog/#{assigns[:record].id}")
            expect(assigns[:record].creator).to eq ['Fleece Vest']
          end
        end

        describe 'when object_as_json is overloaded' do
          before do
            allow(controller).to receive(:object_as_json).and_return(message: 'it works')
          end

          it 'runs object_as_json' do
            post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }, format: 'json'
            expect(JSON.parse(response.body)).to eq('message' => 'it works')
            expect(response.code).to eq '201'
          end
        end

        describe 'when redirect_after_create is overridden' do
          it 'redirects to the alternate location' do
            allow(controller).to receive(:redirect_after_create).and_return('/')
            post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }
            expect(response).to redirect_to('/')
          end
        end
      end

      context 'when it fails to save' do
        before do
          allow(stub_audio).to receive(:save).and_return(false)
        end
        it 'draws the form' do
          post :create, params: { type: model_class.name, model_class.name.underscore => { title: ['My title'] } }
          expect(response).to render_template('records/new')
          expect(assigns[:form].title).to eq ['My title']
          expect(assigns[:form].description).to eq ['']
        end
      end
    end

    describe 'editing a record' do
      let(:audio) { object }
      before do
        allow(audio).to receive(:persisted?).and_return(true)
        allow(ActiveFedora::Base).to receive(:find).and_return(audio)
        allow(controller).to receive(:authorize!)
        allow(object).to receive(:title).and_return(['My title2'])
      end

      it 'updates the audio work' do
        get :edit, params: { id: audio }
        expect(response).to be_successful
        expect(assigns[:record].title).to eq ['My title2']
      end
    end

    describe 'updating a record' do
      let(:audio) { object }
      before do
        allow(audio).to receive(:persisted?).and_return(true)
        allow(ActiveFedora::Base).to receive(:find).with('test-id').and_return(audio)
        allow(controller).to receive(:authorize!)
      end

      context 'when saving is unsuccessful' do
        before do
          allow(audio).to receive(:save).and_return(false)
          allow(form).to receive(:title).and_return(['My title 3'])
        end

        it 'draws the form' do
          put :update, params: { id: audio, model_class.name.underscore => { title: ['My title 3'] } }
          expect(response).to be_successful
          expect(response).to render_template('records/edit')
          expect(assigns[:form].title).to eq ['My title 3']
          expect(assigns[:form].description).to eq ['']
        end
      end

      context 'when saving is successful' do
        before do
          allow(audio).to receive(:save).and_return(true)
          allow(object).to receive(:title).and_return(['My title 3'])
        end

        it 'updates the work and redirects to the work show view' do
          put :update, params: { id: audio, model_class.name.underscore => { title: ['My title 3'] } }
          expect(response).to redirect_to("/catalog/#{assigns[:record].id}")
          expect(assigns[:record].title).to eq ['My title 3']
        end

        it 'is successful with json' do
          put :update, params: { id: audio, model_class.name.underscore => { title: ['My title'] } }, format: :json
          expect(response.status).to eq 204
        end

        context 'when redirect_after_update is overridden' do
          it 'redirects to the alternate location' do
            allow(controller).to receive(:redirect_after_update).and_return('/')
            put :update, params: { id: audio, model_class.name.underscore => { title: ['My title 3'] } }
            expect(response).to redirect_to('/')
          end
        end
      end
    end
  end

  describe 'a user without create ability' do
    let(:user) { FactoryBot.create(:user) }
    before do
      sign_in user
      controller.current_ability.cannot :create, model_class
    end

    describe 'who goes to the new page' do
      it 'is not allowed' do
        get :new, params: { type: model_class.name }
        expect(response).to redirect_to '/'
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
  end
end

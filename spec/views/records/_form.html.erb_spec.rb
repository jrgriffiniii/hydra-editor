require 'spec_helper'

describe 'records/_form', active_fedora_stubbed: true do
  let(:model_class) { TestFedoraModel }
  let(:object) { instance_double(TestFedoraModel) }
  let(:form_class) { class_double(TestFedoraModelForm).as_stubbed_const(transfer_nested_constants: true) }
  let(:form) { instance_double(TestFedoraModelForm) }
  let(:audio) { object }

  before do
    allow(view).to receive(:key).and_return(:title)
    allow(view).to receive(:form).and_return(form)
    allow(view).to receive(:main_app).and_return(Rails.application.routes.url_helpers)
  end

  context 'when there are no errors' do
    it 'does not have the error class' do
      render
      expect(response).to have_selector '.form-group'
      expect(response).not_to have_selector '.has-error'
    end
  end

  context 'when errors are present' do
    let(:errors) { instance_double(ActiveModel::Errors) }

    before do
      allow(errors).to receive(:[]).and_return(["can't be blank"])
      allow(errors).to receive(:full_messages_for).and_return(["can't be blank"])
      allow(form).to receive(:errors).and_return(errors)
    end

    it 'has the error class' do
      render
      expect(response).to have_selector '.form-group.form-group-invalid'
      expect(response).to have_selector '.invalid-feedback', text: "can't be blank"
    end
  end
end

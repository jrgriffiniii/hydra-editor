require 'spec_helper'

describe 'record editing' do
  let(:user) { FactoryBot.create(:user) }
  let(:record) do
    Audio.find_or_create_by(id: 'audio-1', title: ['Cool Track'])
  end

  before do
    HydraEditor.models = ['Audio']
    allow_any_instance_of(Ability).to receive(:authorize!).and_return(true)
    # Avoid the catalog so we don't have to run Solr
    allow_any_instance_of(RecordsController).to receive(:redirect_after_update).and_return('/404.html')
    login_as user
  end

  after do
    Warden.test_reset!
  end
  it 'is idempotent' do
    visit "/records/#{record.id}/edit"
    fill_in 'Title', with: 'Even Better Track'
    click_button 'Save'
    record.reload
    expect(record.title).to eq ['Even Better Track']
    expect(record.creator).to eq []
    expect(record.description).to eq []
    expect(record.subject).to eq []
  end
end

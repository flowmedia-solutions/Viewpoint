$: << File.dirname(__FILE__) + '/../../lib/'
require 'kconv'
require 'viewpoint'
require 'json'

# To run this test put a file called 'creds.json' in this directory with the following format:
#   {"user":"myuser","pass":"mypass","endpoint":"https://mydomain.com/ews/exchange.asmx"}


describe "Folder Synchronization" do
  before(:all) do
    creds = JSON.load(File.open("#{File.dirname(__FILE__)}/creds.json",'r'))
    ViewpointOld::EWS::EWS.endpoint = creds['endpoint']
    ViewpointOld::EWS::EWS.set_auth(creds['user'],creds['pass'])
    @ews = ViewpointOld::EWS::EWS.instance
    @inbox = ViewpointOld::EWS::GenericFolder.get_folder :inbox
  end

  describe "An unsynchronized Inbox Folder" do
    after(:all) do
      @inbox.clear_sync_state!
    end

    it 'should start synchronization of the Inbox Folder' do
      @inbox.sync_items!(2)
      @inbox.sync_state.should_not be_nil
    end

    it 'should synchronized to a given DateTime' do
      @inbox.sync_items_since!(DateTime.parse((Date.today - 1).to_s))
      @inbox.sync_state.should_not be_nil
    end

  end

end

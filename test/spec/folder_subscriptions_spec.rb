$: << File.dirname(__FILE__) + '/../../lib/'
require 'kconv'
require 'viewpoint'
require 'json'

# To run this test put a file called 'creds.json' in this directory with the following format:
#   {"user":"myuser","pass":"mypass","endpoint":"https://mydomain.com/ews/exchange.asmx"}


describe "Folder Subscriptions" do
  before(:all) do
    creds = JSON.load(File.open("#{File.dirname(__FILE__)}/creds.json",'r'))
    ViewpointOld::EWS::EWS.endpoint = creds['endpoint']
    ViewpointOld::EWS::EWS.set_auth(creds['user'],creds['pass'])
    @ews = ViewpointOld::EWS::EWS.instance
    @inbox = ViewpointOld::EWS::GenericFolder.get_folder :inbox
  end

  describe "Example Folder Subscription for the Inbox" do

    it 'should subscribe to the Inbox Folder' do
      @inbox.subscribe.should be_true
    end

    it 'should retrieve new subscription events' do
      @inbox.get_events.should_not be_empty
    end

    it 'should unsubscribe to the Inbox Folder' do
      @inbox.unsubscribe.should be_true
    end

  end

end

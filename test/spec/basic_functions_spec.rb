$: << File.dirname(__FILE__) + '/../../lib/'
require 'kconv'
require 'viewpoint'
require 'json'

# To run this test put a file called 'creds.json' in this directory with the following format:
#   {"user":"myuser","pass":"mypass","endpoint":"https://mydomain.com/ews/exchange.asmx"}


describe "Test the basic features of ViewpointOld" do
  before(:all) do
    creds = JSON.load(File.open("#{File.dirname(__FILE__)}/creds.json",'r'))
    ViewpointOld::EWS::EWS.endpoint = creds['endpoint']
    ViewpointOld::EWS::EWS.set_auth(creds['user'],creds['pass'])
    @ews = ViewpointOld::EWS::EWS.instance
  end

  it 'should retrieve the various Folder Types' do
    (ViewpointOld::EWS::GenericFolder.get_folder :inbox).should be_instance_of(ViewpointOld::EWS::Folder)
    (ViewpointOld::EWS::GenericFolder.get_folder :calendar).should be_instance_of(ViewpointOld::EWS::CalendarFolder)
    (ViewpointOld::EWS::GenericFolder.get_folder :contacts).should be_instance_of(ViewpointOld::EWS::ContactsFolder)
    (ViewpointOld::EWS::GenericFolder.get_folder :tasks).should be_instance_of(ViewpointOld::EWS::TasksFolder)
  end

  it 'should retrive the Inbox by name' do
    (ViewpointOld::EWS::GenericFolder.get_folder_by_name 'Inbox').should be_instance_of(ViewpointOld::EWS::Folder)
  end

  it 'should retrive the Inbox by FolderId' do
    inbox = ViewpointOld::EWS::GenericFolder.get_folder_by_name 'Inbox'
    (ViewpointOld::EWS::GenericFolder.get_folder inbox.id).should be_instance_of(ViewpointOld::EWS::Folder)
  end

  it 'should retrieve an Array of Folder Types' do
    flds = ViewpointOld::EWS::GenericFolder.find_folders
    flds.should be_instance_of(Array)
    flds.first.should be_kind_of(ViewpointOld::EWS::GenericFolder)
  end

  it 'should retrieve messages from a mail folder' do
    inbox = ViewpointOld::EWS::GenericFolder.get_folder :inbox
    msgs  = inbox.find_items
    msgs.should be_instance_of(Array)
    if(msgs.length > 0)
      msgs.first.should be_kind_of(ViewpointOld::EWS::Item)
    end
  end

  it 'should retrieve an item by id if one exists' do
    inbox = ViewpointOld::EWS::GenericFolder.get_folder :inbox
    msgs  = inbox.find_items
    if(msgs.length > 0)
      item = inbox.get_item(msgs.first.id)
      item.should be_kind_of(ViewpointOld::EWS::Item)
    else
      msgs.should be_empty
    end
  end

  it 'should retrieve a folder by name' do
    inbox = ViewpointOld::EWS::GenericFolder.get_folder_by_name("Inbox")
    inbox.should be_instance_of(ViewpointOld::EWS::Folder)
  end

  it 'should retrieve a list of folder names' do
    ViewpointOld::EWS::GenericFolder.folder_names.should_not be_empty
  end

end

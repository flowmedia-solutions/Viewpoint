=begin
  This file is part of ViewpointOld; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2011 Dan Wanek <dan.wanek@gmail.com>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end
module ViewpointOld::EWS::ContactAccessors
  include ViewpointOld::EWS

  # Find contacts in the passed root folder.  If no parameters are passed this
  # method will search from the Root folder.
  # @param [Hash] opts Misc options to control request
  # @option opts [String,Symbol] :root Either a FolderId(String) or a
  #   DistinguishedFolderId(Symbol) . This is where to start the search from.
  #   Usually :root,:msgfolderroot, or :publicfoldersroot
  # @return [Array] Returns an Array of Contact or subclasses of Contact
  # @raise [EwsError] raised when the backend SOAP method returns an error.
  def contacts(opts={})
    opts = opts.clone
    args = find_contacts_args(opts)
    obj = OpenStruct.new(opts: args, restriction: {})
    yield obj if block_given?
    merge_restrictions! obj
    resp = ews.find_contact( args )
    find_contacts_parser(resp)
  end
  alias :find_contacts :contact

  # Get a specific folder by id or symbol
  # @param [String,Symbol,Hash] folder_id Either a FolderId(String) or a
  #   DistinguishedFolderId(Symbol). You can also pass a Hash in the form:
  #   {id: <fold_id>, change_key: <change_key>}
  # @param [Hash] opts Misc options to control request
  # @option opts [Symbol] :shape :id_only/:default/:all_properties
  # @option opts [String,nil] :act_as User to act on behalf as. This user must
  #   have been given delegate access to the folder or this operation will fail.
  # @raise [EwsError] raised when the backend SOAP method returns an error.
  def get_folder(folder_id, opts = {})
    opts = opts.clone
    args = get_folder_args(folder_id, opts)
    resp = ews.get_folder(args)
    get_folder_parser(resp)
  end

  # Get a specific folder by its name
  # @param [String] name The folder name
  # @param [Hash] opts Misc options to control request
  # @option opts [String,Symbol] :parent Either a FolderId(String) or a
  #   DistinguishedFolderId(Symbol) . This is the parent folder.
  # @option opts [Symbol] :shape :id_only/:default/:all_properties
  # @option opts [String,nil] :act_as User to act on behalf as. This user must
  #   have been given delegate access to the folder or this operation will fail.
  # @raise [EwsError] raised when the backend SOAP method returns an error.
  def get_folder_by_name(name, opts={})
    opts = opts.clone
    opts[:root] = opts.delete(:parent)
    folders(opts) do |obj|
      obj.restriction = {
        :is_equal_to =>
        [
          {:field_uRI => {:field_uRI=>'folder:DisplayName'}},
          {:field_uRI_or_constant => {:constant => {:value=>name}}}
        ]
      }
    end.first
  end

  # @param [String] name The name of the new folder
  # @param [Hash] opts
  # @option opts [String,Symbol] :parent Either a FolderId(String) or a
  #   DistinguishedFolderId(Symbol) . This is the parent folder.
  # @option opts [Symbol] :type the type of folder to create. must be one of
  #   :folder, :calendar, :contacts, :search, or :tasks
  # @see http://msdn.microsoft.com/en-us/library/aa580808.aspx
  def make_folder(name, opts={})
    parent = opts[:parent] || :msgfolderroot
    resp = ews.create_folder :parent_folder_id => {:id => parent},
      :folders => [folder_type(opts[:type]) => {:display_name => name}]
    create_folder_parser(resp).first
  end
  alias :mkfolder :make_folder

  # Get a specific folder by id or symbol
  # @param [Hash] opts Misc options to control request
  # @option opts [Symbol] :shape :id_only/:default/:all_properties
  # @option opts [String,Symbol,Hash] :folder_id You can optionally specify a
  #   folder_id to limit the hierarchy synchronization to it. It must be a
  #   FolderId(String), a DistinguishedFolderId(Symbol) or you can pass a Hash
  #   in the form: {id: <fold_id>, change_key: <change_key>}
  # @option opts [String] :sync_state an optional Base64 encoded SyncState
  #   String from a previous sync call.
  # @yield [Hash] yields the formatted argument Hash for last-minute
  #   modification before calling the backend EWS method.
  # @return [Hash] A hash with the following keys
  #   :all_synced, whether or not additional calls are needed to get all folders
  #   :sync_state, the sync state to use for the next call
  #   and the following optional keys depending on the changes
  #   :create, :update, :delete
  # @raise [EwsError] raised when the backend SOAP method returns an error.
  def sync_folders(opts = {})
    opts = opts.clone
    args = sync_folders_args(opts)
    yield args if block_given?
    resp = ews.sync_folder_hierarchy( args )
    sync_folders_parser(resp)
  end


private

  # Build up the arguements for #find_contacts
  def find_contacts_args(opts)
    opts[:root] = opts[:root] || :root
    opts[:traversal] = :shallow
    opts[:shape] = :default
    args = {
      :parent_folder_ids => [{:id => opts[:root]}],
      :traversal => opts[:traversal],
      :folder_shape => {:base_shape => opts[:shape]}
    }
    args[:restriction] = restr if restr
    args
  end

  # @param [ViewpointOld::EWS::SOAP::EwsSoapResponse] resp
  def find_contacts_parser(resp)
    if resp.status == 'Success'
      contacts = resp.response_message[:elems][:root_folder][:elems][0][:folders][:elems]
      return [] if folders.nil?
      folders.collect do |f|
        ftype = f.keys.first
        class_by_name(ftype).new(ews, f[ftype])
      end
    else
      raise EwsFolderNotFound, "Could not retrieve folders. #{resp.code}: #{resp.message}"
    end
  end

  def create_folder_parser(resp)
    if resp.status == 'Success'
      folders = resp.response_message[:elems][:folders][:elems]
      folders.collect do |f|
        ftype = f.keys.first
        class_by_name(ftype).new(ews, f[ftype])
      end
    else
      raise EwsError, "Could not create folder. #{resp.code}: #{resp.message}"
    end
  end

  # Build up the arguements for #get_folder
  def get_folder_args(folder_id, opts)
    opts[:shape] ||= :default
    default_args =  {
      :folder_shape => {:base_shape => opts[:shape]}
    }
    if folder_id.is_a?(Hash)
      default_args[:folder_ids] = [folder_id]
    else
      default_args[:folder_ids] = [{:id => folder_id}]
    end
    default_args.merge opts
  end

  # @param [ViewpointOld::EWS::SOAP::EwsSoapResponse] resp
  def get_folder_parser(resp)
    if(resp.status == 'Success')
      f = resp.response_message[:elems][:folders][:elems][0]
      ftype = f.keys.first
      class_by_name(ftype).new(ews, f[ftype])
    else
      raise EwsFolderNotFound, "Could not retrieve folder. #{resp.code}: #{resp.message}"
    end
  end

  def sync_folders_args(opts)
    opts[:shape] = opts[:shape] || :default
    args = { :folder_shape => {:base_shape => opts[:shape]} }
    if opts[:folder_id]
      folder_id = opts[:folder_id]
      if folder_id.is_a?(Hash)
        args[:sync_folder_id] = folder_id
      else
        args[:sync_folder_id] = {:id => folder_id}
      end
    end
    args[:sync_state] = opts[:sync_state] if opts[:sync_state]
    args
  end

  def sync_folders_parser(resp)
    rmsg = resp.response_messages[0]
    if rmsg.success?
      rhash = {}
      rhash[:all_synced] = rmsg.includes_last_folder_in_range?
      rhash[:sync_state] = rmsg.sync_state
      rmsg.changes.each do |c|
        ctype = c.keys.first
        rhash[ctype] = [] unless rhash.has_key?(ctype)
        if ctype == :delete
          rhash[ctype] << c[ctype][:elems][0][:folder_id][:attribs]
        else
          type = c[ctype][:elems][0].keys.first
          item = class_by_name(type).new(ews, c[ctype][:elems][0][type])
          rhash[ctype] << item
        end
      end
      rhash
    else
      raise EwsError, "Could not synchronize folders. #{rmsg.response_code}: #{rmsg.message_text}"
    end
  end

  # Map a passed parameter to a know folder type mapping. If no mapping
  # exits simply allow the passed in type to be passed to the SOAP call.
  # @param [Symbol] type a symbol in FOLDER_TYPE_MAP
  def map_folder_type(type)
    FOLDER_TYPE_MAP[type] || type
  end

  def folder_type(type)
    case type
    when nil, :folder
      :folder
    when :calendar, :contacts, :search, :tasks
      "#{type}_folder".to_sym
    else
      raise EwsBadArgumentError, "Not a proper folder type: :#{type}"
    end
  end

end

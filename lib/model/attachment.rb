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

module ViewpointOld
  module EWS
    # A generic Attachment.  This class should not be instantiated directly.  You
    # should use one of the subclasses like FileAttachment or ItemAttachment.
    class Attachment
      include Model

      # All Attachment types will have an id.
      attr_reader :id

    end # Attachment
  end # EWS
end # ViewpointOld

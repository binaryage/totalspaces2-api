# = TotalSpaces - Ruby API bindings for TotalSpaces from BinaryAge
#
# == 2013-02 At present this is pre-release, there is no public version of TotalSpaces containing the API.
#
# This gem enables you to get information from and to control {TotalSpaces}[link:http://totalspaces.binaryage.com]
#
# It is the officially supported way of using the API library libtotalspacesapi, and the required dylib 
# comes bundled with this gem. This gem uses {Ruby-FFI}[link:https://github.com/ffi/ffi] to call the functions in the dylib.
# You'll need a sane ruby and compilation environment to install ruby-ffi - it probably won't install immediately with the
# ruby that comes with Mountain Lion because none of the compilation tools are present. We use {homebrew}[link:http://mxcl.github.com/homebrew/]
# and {rbenv}[link:https://github.com/sstephenson/rbenv/] to manage our ruby scripting environment.
# {This simple guide}[link:http://jacobswanner.com/2012/07/13/ruby-1-9-3-without-gcc.html] may help if you are new to this.
#
# You may use this gem in various ways. For instance, you could:
#
# * Display a message or alert when a particular space is moved to
#
# * Automatically change the name of spaces depending on what apps are in them
#
# * Record which spaces certain windows are on, and restoring those windows to those spaces when the owning app restarts
#
# * Trigger moving certain windows between spaces
#
# API support, and support for this gem starts with TotalSpaces v1.1.4. The API is a premium feature,
# and will only work with registered versions of TotalSpaces.
#
# == Download and installation
#
# The latest version of the TotalSpaces gem can be installed with RubyGems:
#
#  % [sudo] gem install totalspaces
#
# Source code can be downloaded on GitHub
#
# * https://github.com/binaryage/totalspaces-api
#
#
# == Documentation
#
# * In progress
#
# == License
#
# The TotalSpaces gem is released under the MIT license:
#
# * http://www.opensource.org/licenses/MIT
#
# The source code of the dylib is not available at this time.
#
#
# == Support and feature requests
#
# * http://support.binaryage.com
#
#
# == Examples
#   require 'totalspaces'
#   
#   TotalSpaces.on_space_change {|from, to| puts "Moving from space #{from} to space #{to}";}
#
#   TotalSpaces.move_to_space(1)
#
#   current_space = TotalSpaces.current_space
#   puts "Current space number: #{current_space}"
#   puts "Current space is called: #{TotalSpaces.name_for_space(current_space)}"
#
#   TotalSpaces.set_name_for_space(1, "Home")
#

require 'ffi'

module TSApi  #:nodoc:
  extend FFI::Library
  ffi_lib File.join(File.dirname(__FILE__), "libtotalspacesapi.dylib")

  attach_function :tsapi_freeString, [:pointer], :void
  
  attach_function :tsapi_libTotalSpacesVersion, [], :pointer
  attach_function :tsapi_apiVersion, [], :pointer
  attach_function :tsapi_totalSpacesVersion, [], :pointer
  
  attach_function :tsapi_currentSpaceNumber, [], :uint
  attach_function :tsapi_spaceNameForSpaceNumber, [:uint], :pointer
  attach_function :tsapi_numberOfSpaces, [], :uint
  attach_function :tsapi_numberOfFullScreens, [], :uint
  attach_function :tsapi_numberOfFullScreensInGrid, [], :uint
  attach_function :tsapi_numberOfDesktops, [], :uint
  attach_function :tsapi_dashboardIsASpace, [], :bool
  
  attach_function :tsapi_definedRows, [], :uint
  attach_function :tsapi_definedColumns, [], :uint
  
  attach_function :tsapi_setDefinedRows, [:uint], :bool
  attach_function :tsapi_setDefinedColumns, [:uint], :bool
  
  attach_function :tsapi_moveToSpace, [:uint], :bool
  attach_function :tsapi_setNameForSpace, [:uint, :string], :bool
  
  callback :space_change_function, [:uint, :uint], :void
  attach_function :tsapi_setSpaceWillChangeCallback, [:space_change_function], :void
  attach_function :tsapi_unsetSpaceWillChangeCallback, [], :void
  
  callback :layout_changed_function, [], :void
  attach_function :tsapi_setLayoutChangedCallback, [:layout_changed_function], :void
  attach_function :tsapi_unsetLayoutChangedCallback, [], :void

  attach_function :tsapi_windowList, [], :pointer
  attach_function :tsapi_freeWindowList, [:pointer], :void
  
  attach_function :tsapi_moveWindowToSpace, [:uint, :uint], :bool
  
  attach_function :tsapi_moveSpaceToPosition, [:uint, :uint], :bool
  
  attach_function :tsapi_addDesktops, [:uint], :bool
  attach_function :tsapi_removeDesktops, [:uint], :bool
end

module TotalSpaces2

  MAX_DESKTOPS = 16
  UNUSED_SPACE_NUMBER_OFFSET = 100

  #--
  # See tslib.h for the structures returned by the C API
  #++

  class Spaces < FFI::Struct  #:nodoc:
    layout :count, :uint,
           :windows_arrays, :pointer
  end
  
  class Space < FFI::Struct  #:nodoc:
    layout :space_number, :uint,
           :count, :uint,
           :windows_array, :pointer
  end
  
  class Window < FFI::Struct  #:nodoc:
    layout :app_name, :string,
           :window_id, :uint,
           :is_on_all_spaces, :bool,
           :title, :string,
           :frame, :string
  end
  
  class << self
    private
    def string_and_free(cstr_pointer)  #:nodoc:
      str = cstr_pointer.get_string(0)
      TSApi.tsapi_freeString(cstr_pointer)
      str
    end
    
    public
    
    # Returns the version of the dylib, a string such as "1.0"
    # You should be using the same dylib version as that returned by the api_version call
    #
    #   puts "libTotalSpaces version: #{TotalSpaces.lib_total_spaces_version}"
    #
    #   if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
    #     puts "Comms error!"
    #     exit(1)
    #   end
    #
    #
    def lib_total_spaces_version
      string_and_free(TSApi.tsapi_libTotalSpacesVersion)
    end

    # Returns the version of the api present in TotalSpaces, a string such as "1.0"
    # You should be using the same dylib version as that returned by the this call
    #
    #   puts "TotalSpaces API version: #{TotalSpaces.api_version}"
    #
    #   if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
    #     puts "Comms error!"
    #     exit(1)
    #   end
    #
    def api_version
      string_and_free(TSApi.tsapi_apiVersion)
    end

    # Returns the version of TotalSpaces running on the system, a string such as "1.1.4"
    #
    #   puts "TotalSpaces version: #{TotalSpaces.total_spaces_version}"
    #
    def total_spaces_version
      string_and_free(TSApi.tsapi_totalSpacesVersion)
    end
    
    # Returns the number of the current space. Numbering starts at 1, except if you have
    # the Dashboard enabled as a space, in which case the Dashboard counts as space 0
    #
    #   puts "Current space number: #{TotalSpaces.current_space}"
    #
    def current_space
      TSApi.tsapi_currentSpaceNumber
    end
    
    # Returns the name for a space. The returned string will be empty if the space number is
    # not valid
    #
    #   current_space = TotalSpaces.current_space
    #   puts "Current space is called: #{TotalSpaces.name_for_space(current_space)}"
    #
    def name_for_space(space_number)
      name = string_and_free(TSApi.tsapi_spaceNameForSpaceNumber(space_number))
      name.force_encoding("UTF-8")
    end
    
    # Returns the total number of spaces including fullscreens, dashboard (if it's a space), 
    # and spaces that are unused in the grid
    #
    #   puts "Total number of spaces: #{TotalSpaces.number_of_spaces}"
    #
    def number_of_spaces
      TSApi.tsapi_numberOfSpaces
    end
    
    # Returns the number of fullscreen apps present
    #
    #   puts "Number of fullscreens: #{TotalSpaces.number_of_fullscreens}"
    #
    def number_of_fullscreens
      TSApi.tsapi_numberOfFullScreens
    end

    # Returns the number of fullscreen apps tht are defined in the grid - this can be defined
    # in Advanced preferences in TotalSpaces.
    # The return value does not depend on how many fullscreens actually exist in the grid - the
    # value is the definition only, there could be fewer than this actually present.
    #
    #   puts "Number of fullscreens in the grid: #{TotalSpaces.number_of_fullscreens_in_grid}"
    #
    def number_of_fullscreens_in_grid
      TSApi.tsapi_numberOfFullScreensInGrid
    end
    
    # Returns the number of desktops that are present in the system. This may be a bigger number
    # that the rows x columns in the grid if more desktops have been created in Mission Control.
    #
    #   puts "Number of desktops: #{TotalSpaces.number_of_desktops}"
    #
    def number_of_desktops
      TSApi.tsapi_numberOfDesktops
    end
    
    # Returns true if the dashboard is configured to appear as a space in Mission Control preferences.
    #
    #   puts "Dashboard is a space: #{TotalSpaces.dashboard_is_a_space?}"
    #
    def dashboard_is_a_space?
      TSApi.tsapi_dashboardIsASpace
    end
    
    # Returns the number of rows defined in TotalSpaces
    #
    #   puts "Number of rows: #{TotalSpaces.grid_rows}"
    #
    def grid_rows
      TSApi.tsapi_definedRows
    end
    
    # Returns the number of columns defined in TotalSpaces
    #
    #   puts "Number of columns: #{TotalSpaces.grid_columns}"
    #
    def grid_columns
      TSApi.tsapi_definedColumns
    end

    # Sets the number of rows defined in TotalSpaces.
    #
    # This does not change the actual number of desktops present, you should 
    # call add_desktops or remove_desktops as appropriate after changing the number
    # of rows.
    #
    #   TotalSpaces.set_grid_rows(3)
    #
    def set_grid_rows(rows)
      TSApi.tsapi_setDefinedRows(rows)
    end
    
    # Sets the number of columns defined in TotalSpaces.
    #
    # This does not change the actual number of desktops present, you should 
    # call add_desktops or remove_desktops as appropriate after changing the number
    # of columns.
    #
    #   TotalSpaces.set_grid_columns(3)
    #
    def set_grid_columns(columns)
      TSApi.tsapi_setDefinedColumns(columns)
    end
    
    # Command TotalSpaces to switch to the given space number.
    # Returns false if the space number was invalid.
    # The on_space_change notification will be sent.
    #
    #   TotalSpaces.move_to_space(1)
    #
    def move_to_space(space_number)
      TSApi.tsapi_moveToSpace(space_number)
    end
    
    # Set the name for a space.
    # Note that using this command will cause a layout notification to be sent.
    # if the new name was different from that previously set.
    # The maximum length for a name is 255 bytes.
    #
    #   TotalSpaces.set_name_for_space(1, "Home")
    #
    def set_name_for_space(space_number, name)
      TSApi.tsapi_setNameForSpace(space_number, name)
    end
    
    # Register for notifications on space change.
    # The given block will be called whenever you move from one space to another. The arguments are
    # the space number you moved from, and the one you are moving to.
    #
    #   TotalSpaces.on_space_change {|from, to| puts "Moving from space #{from} to space #{to}"}
    #   
    #   sleep
    #
    # There can only be one block registered at any time, the most recently registered one will
    # be called.
    # This callback is called just before the space actually changes - current_space will still 
    # report the from space.
    #
    def on_space_change(&block)
      $tsapi_on_space_change_block = block  # prevent GC
      TSApi.tsapi_setSpaceWillChangeCallback(block)
    end
    
    # Cancel the on_space_change notification.
    #
    def cancel_on_space_change
      $tsapi_on_space_change_block = nil
      TSApi.tsapi_unsetSpaceWillChangeCallback
    end

    # Register for notifications on layout change.
    # The given block will be called whenever the layout changes - this could be due to making an app
    # fullscreen, changing a space name, or changing the layout of the TotalSpaces grid. There are no
    # arguments passed to the block.
    #
    #   
    #   TotalSpaces.on_layout_change {puts "Spaces changed"}
    #   
    #   sleep
    #
    # When you get a notification from this method, you should re-fetch any information about the spaces
    # that you may be storing.
    #
    # There can only be one block registered at any time, the most recently registered one will
    # be called.
    #
    def on_layout_change(&block)
      $tsapi_on_layout_change_block = block  # prevent GC
      TSApi.tsapi_setLayoutChangedCallback(block)
    end
    
    # Cancel the layout change notification
    #
    def cancel_on_layout_change
      $tsapi_on_layout_change_block = nil
      TSApi.tsapi_unsetLayoutChangedCallback
    end
    
    # Get a list of all the windows on your mac
    # It returns an array containing a hash for each space.
    # The hash contains the space number (key :space_number) and an array of hashes, one
    # for each window (key :windows). The windows are in front to back order.
    # Each window hash contains a window_id, title, frame, app_name and is_on_all_spaces flag
    #
    # The below example would move the frontmost window to the next space to the right.
    # 
    #   windows = TotalSpaces.window_list
    #   if !windows.empty?
    #     current_space_windows = windows[TotalSpaces.current_space - 1]
    #     front_window = current_space_windows[:windows][0]
    #     TotalSpaces.move_window_to_space(front_window[:window_id], TotalSpaces.current_space + 1)
    #   end
    #
    def window_list
      result = []
      list = TSApi.tsapi_windowList
      main_array = Spaces.new(list)

      (0...main_array[:count]).each do |n|
        result[n] = {}
        windows_array = Space.new(main_array[:windows_arrays] + n * Space.size)
        result[n][:space_number] = windows_array[:space_number]
        result[n][:windows] = []
        (0...windows_array[:count]).each do |m|
          window_hash = result[n][:windows][m] = {}
          window = Window.new(windows_array[:windows_array] + m * Window.size)
          window_hash[:window_id] = window[:window_id]
          window_hash[:title] = window[:title].dup.force_encoding("UTF-8")
          window_hash[:frame] = window[:frame].dup.force_encoding("UTF-8")
          window_hash[:is_on_all_spaces] = window[:is_on_all_spaces]
          window_hash[:app_name] = window[:app_name].dup.force_encoding("UTF-8")
        end
      end
      
      TSApi.tsapi_freeWindowList(list)

      result
    end
    
    # Move a window to a given space
    # The window_id parameter must be fetched using window_list.
    # Returns false if the space_number or window_id is invalid.
    #
    def move_window_to_space(window_id, space_number)
      TSApi.tsapi_moveWindowToSpace(window_id, space_number)
    end
    
    # Move space to a new position
    # You cannot move a space to position 1, and you cannot move the first
    # space anywhere else - it is fixed.
    # You cannot move full screen apps around with this method, only normal desktops
    # Returns false if the space_number or position_number is not valid.
    #
    #   TotalSpaces.move_space_to_position(4, 2)
    #
    def move_space_to_position(space_number, position_number)
      TSApi.tsapi_moveSpaceToPosition(space_number, position_number)
    end
    
    # Add desktops
    # There can be at most 16 desktops
    # Returns true on success, false if number_to_add was zero, or would result 
    # in more than 16 desktops.
    # The on_layout_change notification will be sent if a changed was made.
    #
    #   TotalSpaces.add_desktops(1)
    #
    def add_desktops(number_to_add)
      TSApi.tsapi_addDesktops(number_to_add)
    end
    
    # Remove desktops
    # The highest numbered desktops are removed.
    # Removing a desktop you are currently on will result in TotalSpaces switching to
    # another dektop.
    # Any windows present on a desktop being removed will be moved to one of the
    # remaining desktops.
    # Returns true on success, false if number_to_remove was zero or would result in less
    # than 1 desktop remaining.
    # The on_layout_change notification will be sent if a change was made.
    #
    #   TotalSpaces.remove_desktops(1)
    #
    def remove_desktops(number_to_remove)
      TSApi.tsapi_removeDesktops(number_to_remove)
    end
  end
end

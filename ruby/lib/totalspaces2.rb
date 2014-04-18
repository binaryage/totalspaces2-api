# = TotalSpaces2 - Ruby API bindings for TotalSpaces2 from BinaryAge
#
# This gem enables you to get information from and to control {TotalSpaces2}[link:http://totalspaces.binaryage.com]
#
# It is the officially supported way of using the API library libtotalspaces2api, and the required dylib 
# comes bundled with this gem. This gem uses {Ruby-FFI}[link:https://github.com/ffi/ffi] to call the functions in the dylib.
# You'll need a sane ruby and compilation environment to install ruby-ffi - it probably won't install immediately with the
# ruby that comes with OSX because none of the compilation tools are present. We use {homebrew}[link:http://mxcl.github.com/homebrew/]
# and {rbenv}[link:https://github.com/sstephenson/rbenv/] to manage our ruby scripting environment.
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
# API support, and support for this gem starts with TotalSpaces2 v2.1.0. The API is a premium feature,
# and will only work with registered versions of TotalSpaces2.
#
# == Download and installation
#
# The latest version of the TotalSpaces2 gem can be installed with RubyGems:
#
#  % [sudo] gem install totalspaces2
#
# You will need Xcode installed in order for the C compiler to be present in order to install
# ruby-ffi, which is required (and automatically installed) by the totalspaces2 gem.
#
# Source code can be downloaded on GitHub
#
# * https://github.com/binaryage/totalspaces2-api
#
#
# == Documentation
#
# * http://binaryage.github.io/totalspaces2-api/ruby/rdoc/TotalSpaces2.html
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
# * http://discuss.binaryage.com
#
#
# == Examples
#   require 'totalspaces2'
#   
#   TotalSpaces2.on_space_change {|from, to, display_id| puts "Moving from space #{from} to space #{to}";}
#
#   TotalSpaces2.move_to_space(1)
#
#   current_space = TotalSpaces2.current_space
#   puts "Current space number: #{current_space}"
#   puts "Current space is called: #{TotalSpaces2.name_for_space(current_space)}"
#
#   TotalSpaces2.set_name_for_space(1, "Home")
#

require 'ffi'

module TSApi  #:nodoc:
  extend FFI::Library
  ffi_lib File.join(File.dirname(__FILE__), "libtotalspaces2api.dylib")

  attach_function :tsapi_freeString, [:pointer], :void
  
  attach_function :tsapi_libTotalSpacesVersion, [], :pointer
  attach_function :tsapi_apiVersion, [], :pointer
  attach_function :tsapi_totalSpacesVersion, [], :pointer
  
  attach_function :tsapi_displayList, [], :pointer
  attach_function :tsapi_freeDisplayList, [:pointer], :void
  
  attach_function :tsapi_currentSpaceNumberOnDisplay, [:uint], :uint
  attach_function :tsapi_spaceNameForSpaceNumberOnDisplay, [:uint, :uint], :pointer
  attach_function :tsapi_numberOfSpacesOnDisplay, [:uint], :uint
  
  attach_function :tsapi_definedColumnsOnDisplay, [:uint], :uint
  
  attach_function :tsapi_setDefinedColumnsOnDisplay, [:uint, :uint], :bool
  
  attach_function :tsapi_moveToSpaceOnDisplay, [:uint, :uint], :bool
  attach_function :tsapi_setNameForSpaceOnDisplay, [:uint, :string, :uint], :bool
  
  callback :space_change_function, [:uint, :uint, :uint], :void
  attach_function :tsapi_setSpaceWillChangeCallback, [:space_change_function], :void
  attach_function :tsapi_unsetSpaceWillChangeCallback, [], :void
  
  callback :layout_changed_function, [], :void
  attach_function :tsapi_setLayoutChangedCallback, [:layout_changed_function], :void
  attach_function :tsapi_unsetLayoutChangedCallback, [], :void

  attach_function :tsapi_windowList, [], :pointer
  attach_function :tsapi_freeWindowList, [:pointer], :void
  
  attach_function :tsapi_moveWindowToSpaceOnDisplay, [:uint, :uint, :uint], :bool
  
  attach_function :tsapi_moveSpaceToPositionOnDisplay, [:uint, :uint, :uint], :bool
  attach_function :tsapi_moveSpaceOnDisplayToPositionOnDisplay, [:uint, :uint, :uint, :uint], :bool
  
  attach_function :tsapi_addDesktopsOnDisplay, [:uint, :uint], :uint
  attach_function :tsapi_removeDesktopsOnDisplay, [:uint, :uint], :bool
  
  attach_function :tsapi_setFrontWindow, [:uint], :void
end

module TotalSpaces2

  MAX_DESKTOPS = 16

  #--
  # See TSLib.h for the structures returned by the C API
  #++

  class Display < FFI::Struct  #:nodoc:
    layout :displayID, :uint32,
           :display_name, :string,
           :width, :size_t,
           :height, :size_t
  end

  class Displays < FFI::Struct  #:nodoc:
    layout :count, :uint,
           :displays_array, :pointer
    
    def display_info
      displays = []
      displays_array = self[:displays_array]
      (0...self[:count]).each do |n|
        display = Display.new(displays_array + n * Display.size)
        info = {
          display_id: display[:displayID],
          display_name: display[:display_name],
          width: display[:width],
          height: display[:height]
        }
        displays << info
      end
      
      displays
    end
  end

  class Windows < FFI::Struct  #:nodoc:
    layout :count, :uint,
           :windows_array, :pointer
  end
    
  class Window < FFI::Struct  #:nodoc:
    layout :app_name, :string,
           :window_id, :uint,
           :is_on_all_spaces, :bool,
           :title, :string,
           :frame, :string,
           :display_id, :uint,
           :space_number, :uint
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
    # You should be using the same dylib major version number as that returned by the api_version call
    #
    #   puts "libTotalSpaces2 version: #{TotalSpaces2.lib_total_spaces_version}"
    #
    #   if TotalSpaces2.lib_total_spaces_version.split('.')[0] != TotalSpaces2.api_version.split('.')[0]
    #     puts "Comms error!"
    #     exit(1)
    #   end
    #
    #
    def lib_total_spaces_version
      string_and_free(TSApi.tsapi_libTotalSpacesVersion)
    end

    # Returns the version of the api present in TotalSpaces2, a string such as "1.0"
    # You should be using the same dylib version as that returned by the this call
    #
    #   puts "TotalSpaces2 API version: #{TotalSpaces2.api_version}"
    #
    #    if TotalSpaces2.lib_total_spaces_version.split('.')[0] != TotalSpaces2.api_version.split('.')[0]
    #     puts "Comms error!"
    #     exit(1)
    #   end
    #
    def api_version
      string_and_free(TSApi.tsapi_apiVersion)
    end

    # Returns the version of TotalSpaces2 running on the system, a string such as "2.0.12"
    #
    #   puts "TotalSpaces2 version: #{TotalSpaces2.total_spaces_version}"
    #
    def total_spaces_version
      string_and_free(TSApi.tsapi_totalSpacesVersion)
    end

    # Returns an array of hashes with information about attached displays. The ids returned
    # from this call can be used where a display id is required in the other calls in this library.
    #
    #   puts "Attached displays: #{TotalSpaces2.display_list}"
    #
    #   [{:display_id=>69679040, :display_name=>"Color LCD", :width=>1440, :height=>900}, 
    #   {:display_id=>69514913, :display_name=>"LED Cinema Display", :width=>2560, :height=>1440}]
    #
    def display_list
      list = TSApi.tsapi_displayList
      displays = Displays.new(list)
      result = displays.null? ? [] : displays.display_info
      TSApi.tsapi_freeDisplayList(list)
      result
    end

    # Returns information about the main display.
    # Methods that do not take a display id always operate on this display.
    #
    #   puts "Main display id: #{TotalSpaces2.main_display_id}"
    #
    #   {:display_id=>69679040, :display_name=>"Color LCD", :width=>1440, :height=>900}
    #
    def main_display
      self.display_list[0]
    end
    
    # Returns the number of the current space on the main display. Numbering starts at 1.
    #
    #   puts "Current space number: #{TotalSpaces2.current_space}"
    #
    def current_space
      TSApi.tsapi_currentSpaceNumberOnDisplay(0)
    end

    # Returns the number of the current space on the given display. 
    # Space numbering starts at 1
    #
    #   display_id = TotalSpaces2.displays[0]
    #   puts "Current space number: #{TotalSpaces2.current_space_on_display(display_id)}"
    #
    def current_space_on_display(display_id)
      TSApi.tsapi_currentSpaceNumberOnDisplay(display_id)
    end
    
    # Returns the name for a space on the main display. The returned string will be empty 
    # if the space number is not valid
    #
    #   current_space = TotalSpaces2.current_space
    #   puts "Current space is called: #{TotalSpaces2.name_for_space(current_space)}"
    #
    def name_for_space(space_number)
      name = string_and_free(TSApi.tsapi_spaceNameForSpaceNumberOnDisplay(space_number, 0))
      name.force_encoding("UTF-8")
    end

    # Returns the name for a space. The returned string will be empty if the space number is
    # not valid
    #
    #   current_space = TotalSpaces2.current_space
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   puts "Current space is called: #{TotalSpaces2.name_for_space_on_display(current_space, display_id)}"
    #
    def name_for_space_on_display(space_number, display_id)
      name = string_and_free(TSApi.tsapi_spaceNameForSpaceNumberOnDisplay(space_number, display_id))
      name.force_encoding("UTF-8")
    end
    
    # Returns the total number of spaces including fullscreens, dashboard (if it's a space).
    #
    #   puts "Total number of spaces: #{TotalSpaces2.number_of_spaces}"
    #
    def number_of_spaces
      TSApi.tsapi_numberOfSpacesOnDisplay(0)
    end
    
    # Returns the total number of spaces including fullscreens, dashboard (if it's a space).
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   puts "Total number of spaces: #{TotalSpaces2.number_of_spaces_on_display(display_id)}"
    #
    def number_of_spaces_on_display(display_id)
      TSApi.tsapi_numberOfSpacesOnDisplay(display_id)
    end
    
    # Returns the number of columns defined in TotalSpaces2 for the main display
    #
    #   puts "Number of columns: #{TotalSpaces2.grid_columns}"
    #
    def grid_columns
      TSApi.tsapi_definedColumnsOnDisplay(0)
    end
    
    # Returns the number of columns defined in TotalSpaces2
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   puts "Number of columns: #{TotalSpaces2.grid_columns_on_display(display_id)}"
    #
    def grid_columns_on_display(display_id)
      TSApi.tsapi_definedColumnsOnDisplay(display_id)
    end
    
    # Sets the number of columns defined in TotalSpaces2 for the main display.
    #
    # This does not change the actual number of desktops present, you should 
    # call add_desktops or remove_desktops as appropriate after changing the number
    # of columns.
    #
    #   TotalSpaces2.set_grid_columns(3)
    #
    def set_grid_columns(columns)
      TSApi.tsapi_setDefinedColumnsOnDisplay(columns, 0)
    end
    
    # Sets the number of columns defined in TotalSpaces2.
    #
    # This does not change the actual number of desktops present, you should 
    # call add_desktops_on_display or remove_desktops_on_display as appropriate 
    # after changing the number of columns.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   TotalSpaces2.set_grid_columns_on_display(3, display_id)
    #
    def set_grid_columns_on_display(columns, display_id)
      TSApi.tsapi_setDefinedColumnsOnDisplay(columns, display_id)
    end
    
    # Command TotalSpaces2 to switch to the given space number on the main display.
    # Returns false if the space number was invalid.
    # The on_space_change notification will be sent.
    #
    #   TotalSpaces2.move_to_space(1)
    #
    def move_to_space(space_number)
      TSApi.tsapi_moveToSpaceOnDisplay(space_number, 0)
    end
    
    # Command TotalSpaces2 to switch to the given space number.
    # Returns false if the space number was invalid.
    # The on_space_change notification will be sent.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   TotalSpaces2.move_to_space_on_Display(1, display_id)
    #
    def move_to_space_on_display(space_number, display_id)
      TSApi.tsapi_moveToSpaceOnDisplay(space_number, display_id)
    end
    
    # Set the name for a space on the main display.
    # Note that using this command will cause a layout change notification to be sent
    # if the new name was different from that previously set.
    # The maximum length for a name is 255 bytes.
    #
    #   TotalSpaces2.set_name_for_space(1, "Home")
    #
    def set_name_for_space(space_number, name)
      TSApi.tsapi_setNameForSpaceOnDisplay(space_number, name, 0)
    end

    # Set the name for a space.
    # Note that using this command will cause a layout change notification to be sent
    # if the new name was different from that previously set.
    # The maximum length for a name is 255 bytes.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   TotalSpaces2.set_name_for_space_on_display(1, "Home", display_id)
    #
    def set_name_for_space_on_display(space_number, name, display_id)
      TSApi.tsapi_setNameForSpaceOnDisplay(space_number, name, display_id)
    end
    
    # Register for notifications on space change.
    # The given block will be called whenever you move from one space to another. The arguments are
    # the space number you moved from, and the one you are moving to.
    #
    #   TotalSpaces2.on_space_change {|from, to, displayID| puts "Moving from space #{from} to space #{to}"}
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
    # fullscreen, changing a space name, or changing the layout of the TotalSpaces2 grid. There are no
    # arguments passed to the block.
    #
    #   
    #   TotalSpaces2.on_layout_change {puts "Spaces changed"}
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
    # It returns an array containing a hash for each window.
    # The hash contains the display id (key :display_id) and space number (key :space_number) 
    # and details for each window.
    # The windows are in front to back order within each space.
    # Each window hash also contains a window_id, title, frame, app_name and is_on_all_spaces flag
    #
    # The below example would move the frontmost window to the next space to the right.
    # 
    #   windows = TotalSpaces2.window_list
    #   current_space = TotalSpaces2.current_space
    #   main_display_id = TotalSpaces2.main_display[:display_id]
    #   if !windows.empty?
    #     current_space_windows = windows.select {|window| window[:display_id] == main_display_id 
    #                                                      && window[:space_number] == current_space}
    #     front_window = current_space_windows[0]
    #     TotalSpaces2.move_window_to_space(front_window[:window_id], TotalSpaces.current_space + 1)
    #   end
    #
    def window_list
      result = []
      list = TSApi.tsapi_windowList
      main_array = Windows.new(list)

      (0...main_array[:count]).each do |n|
        window = Window.new(main_array[:windows_array] + n * Window.size)
        window_hash = {}
        window_hash[:window_id] = window[:window_id]
        window_hash[:title] = window[:title].dup.force_encoding("UTF-8")
        window_hash[:frame] = window[:frame].dup.force_encoding("UTF-8")
        window_hash[:is_on_all_spaces] = window[:is_on_all_spaces]
        window_hash[:app_name] = window[:app_name].dup.force_encoding("UTF-8")
        window_hash[:display_id] = window[:display_id]
        window_hash[:space_number] = window[:space_number]
        result << window_hash
      end
      
      TSApi.tsapi_freeWindowList(list)

      result
    end
    
    # Move a window to a given space
    # The window_id parameter must be fetched using window_list.
    # Returns false if the space_number or window_id is invalid.
    #
    def move_window_to_space(window_id, space_number)
      TSApi.tsapi_moveWindowToSpaceOnDisplay(window_id, space_number, 0)
    end
    
    # Move a window to a given space on the main display
    # The window_id parameter must be fetched using window_list.
    # Returns false if the space_number or window_id is invalid.
    #
    def move_window_to_space_on_display(window_id, space_number, display_id)
      TSApi.tsapi_moveWindowToSpaceOnDisplay(window_id, space_number, display_id)
    end
    
    # Move space to a new position in the grid on the main display.
    #
    # Returns false if the space_number or position_number is not valid.
    #
    #   TotalSpaces2.move_space_to_position(4, 2)
    #
    def move_space_to_position(space_number, position_number)
      TSApi.tsapi_moveSpaceToPositionOnDisplay(space_number, position_number, 0)
    end

    # Move space to a new position in the grid. Spaces can only be moved 
    # within their own display.
    #
    # Returns false if the space_number or position_number is not valid.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   TotalSpaces2.move_space_to_position_on_display(4, 2, display_id)
    #
    def move_space_to_position_on_display(space_number, position_number, display_id)
      TSApi.tsapi_moveSpaceToPositionOnDisplay(space_number, position_number, display_id)
    end
    
    # Move space to a new position on another screen.
    # This won't work if you do not have displays have separate spaces enabled.
    #
    # Returns false any parameters are not valid.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   display2_id = TotalSpaces2.display_list[1][:display_id]
    #   TotalSpaces2.move_space_on_display_to_position_on_display(2, display_id, 1, display2_id)
    #
    def move_space_on_display_to_position_on_display(space_number, from_display_id, position_number, to_display_id)
      TSApi.tsapi_moveSpaceOnDisplayToPositionOnDisplay(space_number, from_display_id, position_number, to_display_id)
    end

    # Add desktops
    # There can be at most 16 desktops unless the display has collected some when
    # a secondary display has been unplugged.
    # Returns true on success, false if number_to_add was zero, or would result 
    # in more than 16 desktops.
    # The on_layout_change notification will be sent if a changed was made.
    #
    #   TotalSpaces2.add_desktops(1)
    #
    def add_desktops(number_to_add)
      TSApi.tsapi_addDesktopsOnDisplay(number_to_add, 0)
    end

    # Add desktops
    # There can be at most 16 desktops unless the display has collected some when
    # a secondary display has been unplugged.
    # Returns true on success, false if number_to_add was zero, or would result 
    # in more than 16 desktops.
    # The on_layout_change notification will be sent if a changed was made.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   TotalSpaces2.add_desktops_on_display(1, display_id)
    #
    def add_desktops_on_display(number_to_add, display_id)
      TSApi.tsapi_addDesktopsOnDisplay(number_to_add, display_id)
    end
    
    # Remove desktops
    # The highest numbered desktops are removed.
    # Removing a desktop you are currently on will result in TotalSpaces2 switching to
    # another dektop.
    # Any windows present on a desktop being removed will be moved to one of the
    # remaining desktops.
    # Returns true on success, false if number_to_remove was zero or would result in less
    # than 1 desktop remaining.
    # The on_layout_change notification will be sent if a change was made.
    #
    #   TotalSpaces2.remove_desktops(1)
    #
    def remove_desktops(number_to_remove)
      TSApi.tsapi_removeDesktopsOnDisplay(number_to_remove, 0)
    end

    # Remove desktops
    # The highest numbered desktops are removed.
    # Removing a desktop you are currently on will result in TotalSpaces2 switching to
    # another dektop.
    # Any windows present on a desktop being removed will be moved to one of the
    # remaining desktops.
    # Returns true on success, false if number_to_remove was zero or would result in less
    # than 1 desktop remaining.
    # The on_layout_change notification will be sent if a change was made.
    #
    #   display_id = TotalSpaces2.main_display[:display_id]
    #   TotalSpaces2.remove_desktops_on_display(1, display_id)
    #
    def remove_desktops_on_display(number_to_remove, display_id)
      TSApi.tsapi_removeDesktopsOnDisplay(number_to_remove, display_id)
    end
    
    # Move a particular window to the front and activate it.
    # This might be usful after moving windows to other desktops.
    #
    def set_front_window(window_id)
      TSApi.tsapi_setFrontWindow(window_id)
    end
  end
end

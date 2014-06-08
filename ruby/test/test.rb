# Set the transitions speed slider to the fastest position
# in Layout prefs before running these tests

require 'rubygems'

require 'test/unit'

PathHere = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(PathHere, "..", "lib")

require 'totalspaces2'

class TotalSpaces2Test < Test::Unit::TestCase
  def wait_for_change_count_to_increment
    time = Time.now
    prev = @change_count
    while @change_count == prev && Time.now - time < 1
      sleep(0.25)
    end
  end
  
  def wait_for_layout_change
    time = Time.now
    while !@layout_changed && Time.now - time < 1
      sleep(0.25)
    end
  end
  
  def test_api_major_version_should_match
    assert_equal TotalSpaces2.lib_total_spaces_version.split('.')[0], TotalSpaces2.api_version.split('.')[0]
  end
  
  def test_should_change_space_on_main_display
    TotalSpaces2.on_space_change do |from, to, displayID|
      @reported_space = to
      @change_count += 1
    end

    @change_count = 0
    
    current_space = TotalSpaces2.current_space
    new_space = (current_space > 1) ? 1 : 2

    TotalSpaces2.move_to_space_on_display(new_space, 0)

    wait_for_change_count_to_increment
    
    assert_equal new_space, @reported_space
    
    TotalSpaces2.move_to_space_on_display(current_space, 0)
    
    wait_for_change_count_to_increment
    
    assert_equal current_space, @reported_space
    
    assert_equal 2, @change_count
    
    TotalSpaces2.cancel_on_space_change
  end
  
  def test_main_display_is_first_reported_display
    displays = TotalSpaces2.display_list
    display_id = displays[0][:display_id]
    assert_not_equal 0, display_id
    
    current_space = TotalSpaces2.current_space
    new_space = (current_space > 1) ? 1 : 2
    
    assert_equal current_space, TotalSpaces2.current_space_on_display(display_id)

    old_name = TotalSpaces2.name_for_space_on_display(1, display_id)
    
    TotalSpaces2.set_name_for_space_on_display(1, "test_name", display_id)
    
    new_name1 = TotalSpaces2.name_for_space_on_display(1, display_id)
    
    new_name2 = TotalSpaces2.name_for_space_on_display(1, 0)
    
    TotalSpaces2.set_name_for_space_on_display(1, old_name, display_id)

    assert_equal "test_name", new_name1
    assert_equal "test_name", new_name2
  end
  
  def test_adding_and_removing_a_desktop
    original_number = TotalSpaces2.number_of_spaces_on_display(0)
    assert_equal 1, TotalSpaces2.add_desktops_on_display(1, 0)

    assert_equal original_number + 1, TotalSpaces2.number_of_spaces_on_display(0)
    
    TotalSpaces2.remove_desktops_on_display(1, 0)
    assert_equal original_number, TotalSpaces2.number_of_spaces_on_display(0)
  end
  
  def test_reading_and_setting_defined_columns
    original_number = TotalSpaces2.grid_columns_on_display(0)
    TotalSpaces2.set_grid_columns_on_display(original_number + 1, 0)
    new_number = TotalSpaces2.grid_columns_on_display(0)
    assert_equal original_number + 1, new_number
    TotalSpaces2.set_grid_columns_on_display(original_number, 0)    
  end
  
  def test_setting_defined_columns_triggers_layout_change_callback
    TotalSpaces2.on_layout_change do
      @layout_changed = true
    end
    
    @layout_changed = false
    original_number = TotalSpaces2.grid_columns_on_display(0)
    TotalSpaces2.set_grid_columns_on_display(original_number + 1, 0)

    wait_for_layout_change
    
    TotalSpaces2.set_grid_columns_on_display(original_number, 0)
    
    assert @layout_changed
    
    TotalSpaces2.cancel_on_layout_change
  end
  
  def test_can_cancel_space_change_callback
    TotalSpaces2.on_space_change do |from, to, displayID|
      @change_count += 1
    end
    
    @change_count = 0
    
    current_space = TotalSpaces2.current_space
    new_space = (current_space > 1) ? 1 : 2
    
    TotalSpaces2.move_to_space_on_display(new_space, 0)
    
    wait_for_change_count_to_increment
    
    assert_equal 1, @change_count
    
    TotalSpaces2.move_to_space_on_display(current_space, 0)

    wait_for_change_count_to_increment

    assert_equal current_space, TotalSpaces2.current_space
    
    assert_equal 2, @change_count

    TotalSpaces2.cancel_on_space_change
    
    TotalSpaces2.move_to_space_on_display(new_space, 0)
    
    wait_for_change_count_to_increment
    
    assert_equal 2, @change_count
    
    TotalSpaces2.move_to_space_on_display(current_space, 0)
    
    wait_for_change_count_to_increment

    assert_equal 2, @change_count
  end
  
  def test_can_cancel_layout_change_callback
    TotalSpaces2.on_layout_change do
      @layout_changed = true
    end
    
    @layout_changed = false
    original_number = TotalSpaces2.grid_columns_on_display(0)
    TotalSpaces2.set_grid_columns_on_display(original_number + 1, 0)    
    wait_for_layout_change

    first_change = @layout_changed

    @layout_changed = false
    TotalSpaces2.set_grid_columns_on_display(original_number, 0)
    wait_for_layout_change

    assert first_change
    assert @layout_changed

    TotalSpaces2.cancel_on_layout_change

    @layout_changed = false
    original_number = TotalSpaces2.grid_columns_on_display(0)
    TotalSpaces2.set_grid_columns_on_display(original_number + 1, 0)

    wait_for_layout_change
    
    TotalSpaces2.set_grid_columns_on_display(original_number, 0)
    
    assert !@layout_changed
  end
  
  def test_window_in_window_list_has_right_keys
    list = TotalSpaces2.window_list
    window = list[0]
    assert_equal %i{window_id title frame is_on_all_spaces app_name display_id space_number}.sort, window.keys.sort
  end
  
  def test_can_move_window
    list = TotalSpaces2.window_list
    window = list[0]
    current_space = window[:space_number]
    new_space = (current_space > 1) ? 1 : 2
    window_id = window[:window_id]
    TotalSpaces2.move_window_to_space_on_display(window_id, new_space, window[:display_id])

    list = TotalSpaces2.window_list
    window = list.detect {|w| w[:window_id] == window_id}
    TotalSpaces2.move_window_to_space_on_display(window_id, current_space, window[:display_id])    

    assert_equal new_space, window[:space_number]
  end
  
  def test_move_space_triggers_layout_change
    TotalSpaces2.on_layout_change do
      @layout_changed = true
    end

    TotalSpaces2.move_space_to_position_on_display(1, 2, 0)
    
    @layout_changed = false
    wait_for_layout_change

    TotalSpaces2.move_space_to_position_on_display(2, 1, 0)

    assert @layout_changed
    
    TotalSpaces2.cancel_on_layout_change
  end
  
  
  def test_can_move_space
    TotalSpaces2.on_layout_change do
      @layout_changed = true
    end
    
    old_name = TotalSpaces2.name_for_space_on_display(1, 0)
    
    TotalSpaces2.set_name_for_space_on_display(1, "move_space", 0)
    
    TotalSpaces2.move_space_to_position_on_display(1, 2, 0)

    @layout_changed = false
    wait_for_layout_change
        
    new_name = TotalSpaces2.name_for_space_on_display(2, 0)
    
    TotalSpaces2.move_space_to_position_on_display(2, 1, 0)
    
    TotalSpaces2.set_name_for_space_on_display(1, old_name, 0)
    
    assert_equal "move_space", new_name
    
    TotalSpaces2.cancel_on_layout_change
  end
  
  def test_activate_front_window
    current_space = TotalSpaces2.current_space
    list = TotalSpaces2.window_list.select {|window| window[:space_number] == current_space}
    window = list[0]
    window2 = list[1]
    assert window && window2, "you need 2 windows on the current space for this test to work"
    window_id = window[:window_id]
    window2_id = window2[:window_id]
    
    TotalSpaces2.set_front_window(window2_id)

    list2 = TotalSpaces2.window_list.select {|window| window[:space_number] == current_space}
    top_window_after_set_front = list2[0]
    TotalSpaces2.set_front_window(window_id)
    assert_equal window2_id, top_window_after_set_front[:window_id]
  end
end

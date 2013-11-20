require 'totalspaces'

if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
  puts "Comms error!"
  exit(1)
end

rows, columns = TotalSpaces.grid_rows, TotalSpaces.grid_columns

desktops = TotalSpaces.number_of_desktops

new_columns = columns - 1

if new_columns == 0
  puts "Can't remove any more columns"
  exit(1)
end

current_grid_total = rows * columns

if desktops < current_grid_total
  puts "Must start with enough desktops to fill your grid"
  exit(1)
end

if TotalSpaces.number_of_fullscreens_in_grid > 0
  puts "This can't work when there are fullscreens in the grid"
  exit(1)
end

first_desktop_to_remove = rows * new_columns + 1

(rows - 2).downto(0) do |n|
  TotalSpaces.move_space_to_position(columns * (n + 1), first_desktop_to_remove + n)
end

if !TotalSpaces.set_grid_columns(new_columns)
  puts "Couldn't set new dimensions"
  exit(1)
end

if !TotalSpaces.remove_desktops(rows)
  puts "Couldn't remove desktops"
end

# Done

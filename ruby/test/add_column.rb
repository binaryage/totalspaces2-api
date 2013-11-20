require 'totalspaces'

if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
  puts "Comms error!"
  exit(1)
end

rows, columns = TotalSpaces.grid_rows, TotalSpaces.grid_columns

desktops = TotalSpaces.number_of_desktops
current_grid_total = rows * columns

if desktops < current_grid_total
  puts "Must start with enough desktops to fill your grid"
  exit(1)
end

if TotalSpaces.number_of_fullscreens_in_grid > 0
  puts "This can't work when there are fullscreens in the grid"
  exit(1)
end

if current_grid_total + rows > TotalSpaces::MAX_DESKTOPS
  puts "No room for another column"
  exit(1)
end

new_columns = columns + 1

if !TotalSpaces.set_grid_columns(new_columns)
  puts "Couldn't set new dimensions"
  exit(1)
end

# use up any existing extra desktops that aren't in the grid
desktops_to_add = rows - (desktops - current_grid_total)

if desktops_to_add > 0 && !TotalSpaces.add_desktops(desktops_to_add)
  puts "Couldn't add desktops"
  exit(1)
end

first_new_desktop = current_grid_total + 1

0.upto(rows - 2) do |n|
  TotalSpaces.move_space_to_position(first_new_desktop + n, new_columns * (n + 1))
end

# Done

require 'totalspaces'

if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
  puts "Comms error!"
  exit(1)
end

TotalSpaces.on_space_change do |from, to|
  name = TotalSpaces.name_for_space(to)
  puts "Changing space to #{name} (space number #{to})"
end

sleep

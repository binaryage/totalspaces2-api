PathHere = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(PathHere, "..", "lib")

require 'totalspaces2'

if TotalSpaces2.lib_total_spaces_version.split('.')[0] != TotalSpaces2.api_version.split('.')[0]
  puts "Version error!"
  exit(1)
end

TotalSpaces2.on_space_change do |from, to, display_id|
  name = TotalSpaces2.name_for_space_on_display(to, display_id)
  puts "Changing space to #{name} (space number #{to})"
end

sleep

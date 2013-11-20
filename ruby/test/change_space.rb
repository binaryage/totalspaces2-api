require 'totalspaces'

if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
  puts "Comms error!"
  exit(1)
end

TotalSpaces.move_to_space(ARGV[0].to_i)

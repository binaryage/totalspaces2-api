require './lib/totalspaces2.rb'

if TotalSpaces2.lib_total_spaces_version.split('.')[0] != TotalSpaces2.api_version.split('.')[0]
  puts "Version error!"
  exit(1)
end

TotalSpaces2.move_to_space_on_display(ARGV[0].to_i, 0)

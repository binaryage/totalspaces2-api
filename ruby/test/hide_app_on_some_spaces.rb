require 'totalspaces'

if TotalSpaces.lib_total_spaces_version != TotalSpaces.api_version
  puts "Comms error!"
  exit(1)
end

TotalSpaces.on_space_change do |from, to|
  if to == 3 || to == 4
    # hide
    %x{osascript -e 'tell application "Finder"
      set visible of process "iCal" to false
      end tell'}
  else
    # unhide
    puts "space = #{to}, showing"
    %x{osascript -e 'tell application "Finder"
      set visible of process "iCal" to true
      end tell'}
  end
end

sleep


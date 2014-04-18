require 'totalspaces2'
require 'json'

CONFIG_FILE = File.expand_path('~/.ts2_spaces_configs')

def current_space_info
  space_displays = {}
  space_numbers = {}

  displays = TotalSpaces2.display_list
  display_ids = displays.collect{|d| d[:display_id]}

  display_ids.each do |display_id|
    num_spaces = TotalSpaces2.number_of_spaces_on_display(display_id)
    1.upto(num_spaces) do |space_num|
      uuid = TotalSpaces2.uuid_for_space_on_display(space_num, display_id)
      space_displays[uuid] = display_id
      space_numbers[uuid] = space_num
    end
  end
  
  return space_displays, space_numbers
end


name = ARGV[0]
if !name
  puts "Please supply a name for the setting to read"
  exit(1)
end

if TotalSpaces2.lib_total_spaces_version.split('.')[0] != TotalSpaces2.api_version.split('.')[0]
  puts "Version error!"
  exit(1)
end

if File.exist?(CONFIG_FILE)
  configs = JSON.parse(File.read(CONFIG_FILE))
else
  configs = {}
end

if !configs.is_a?(Hash)
  configs = {}
end

config = configs[name]

if !config
  puts "Setting not found"
  exit(2)
end

displays = TotalSpaces2.display_list
display_ids = displays.collect{|d| d[:display_id]}
config.each do |display_id, spaces|
  if !display_ids.include?(display_id.to_i)
    puts "Display not found, this config is for different displays"
    exit(3)
  end
end

space_displays, space_numbers = current_space_info
config.each do |display_id, spaces|
  target_display_id = display_id.to_i
  target_position = 1
  spaces.each do |space_id|
    from_display_id = space_displays[space_id]
    if from_display_id && target_display_id != from_display_id
#      puts "Moving space #{space_numbers[space_id]} (#{from_display_id}) to #{target_position} (#{target_display_id})"
      result = TotalSpaces2.move_space_on_display_to_position_on_display(space_numbers[space_id], from_display_id, target_position, target_display_id)
      if !result
        # retry
        sleep 0.5
        space_displays, space_numbers = current_space_info

        result = TotalSpaces2.move_space_on_display_to_position_on_display(space_numbers[space_id], from_display_id, target_position, target_display_id)
        if !result
          puts "Failed to move space #{space_numbers[space_id]} to position #{target_position}"
        end
      end
      # re-fetch info because layout has now changed
      space_displays, space_numbers = current_space_info
    end
    target_position += 1
  end
end

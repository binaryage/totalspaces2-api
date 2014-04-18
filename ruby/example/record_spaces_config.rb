require 'totalspaces2'
require 'json'

CONFIG_FILE = File.expand_path('~/.ts2_spaces_configs')

name = ARGV[0]
if !name
  puts "Please supply a name for the setting"
  exit(1)
end

if TotalSpaces2.lib_total_spaces_version.split('.')[0] != TotalSpaces2.api_version.split('.')[0]
  puts "Version error!"
  exit(1)
end

ts_config = {}

displays = TotalSpaces2.display_list
display_ids = displays.collect{|d| d[:display_id]}

display_ids.each do |display_id|
  disp_config = ts_config[display_id] = []
  
  num_spaces = TotalSpaces2.number_of_spaces_on_display(display_id)
  1.upto(num_spaces) do |space_num|
    disp_config << TotalSpaces2.uuid_for_space_on_display(space_num, display_id)
  end
end

if File.exist?(CONFIG_FILE)
  configs = JSON.parse(File.read(CONFIG_FILE))
else
  configs = {}
end

if !configs.is_a?(Hash)
  configs = {}
end

configs[name] = ts_config

File.open(CONFIG_FILE, 'w') {|file| file.write(JSON.generate(configs))}

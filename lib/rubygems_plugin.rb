require 'rubygems/command_manager'

Dir.glob(File.join(File.dirname(__FILE__), 'commands', '*_command.rb')) do |path|
  require "commands/#{File.basename(path)}"
  Gem::CommandManager.instance.register_command File.basename(path, '_command.rb').to_sym
end

require 'rubygems/command'

require File.expand_path('world_command', File.dirname(__FILE__))

class Gem::Commands::DepcleanCommand < Gem::Command
  def initialize
    super 'depclean', 'Uninstall all unnecessary gems'
  end

  def execute
    alert_warning "'gem depclean' is obsolete. Use 'gem world --depclean' instead."
    Gem::Commands::WorldCommand.new.depclean
  end
end

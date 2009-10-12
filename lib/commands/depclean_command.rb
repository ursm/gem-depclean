require 'rubygems/command'
require 'rubygems/uninstaller'
require 'set'

class Gem::Commands::DepcleanCommand < Gem::Command
  def initialize
    super 'depclean', 'Uninstall all unnecessary gems'
  end

  def world
    Gem::CommandManager.instance['world']
  end

  def execute
    gems = world.world_gems.inject(Set.new) {|acc, gem|
      acc + collect_dependencies(gem)
    }

    targets = (Gem.source_index.map(&:last) - gems.to_a).sort_by(&:name)

    if targets.empty?
      say 'Your world is already clean.'
      return
    end


    targets.each do |t|
      say "#{t.name} (#{t.version})"
    end

    return unless ask_yes_no 'Would you like to uninstall these gems?'

    targets.each do |gem|
      Gem::Uninstaller.new(gem.name, :version => gem.version, :ignore => true).uninstall
    end
  end

  def collect_dependencies(gem, acc = Set.new)
    acc << gem

    gem.dependencies.map {|dep|
      Gem.source_index.find_name(dep.name, dep.version_requirements).sort_by(&:version).last
    }.compact.reject {|s| acc.include?(s) }.each do |dep|
      collect_dependencies(dep, acc)
    end

    acc
  end
end

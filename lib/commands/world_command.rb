require 'rubygems/command'
require 'rubygems/requirement'
require 'yaml'

class Gem::Commands::WorldCommand < Gem::Command
  Gem.post_install do |installer|
    command = Gem::CommandManager.instance['install']
    name = installer.spec.name

    if command.get_all_gem_names.include?(name)
      new.add name, command.options[:version]
    end
  end

  def initialize
    super 'world', 'Display gems that in your world'

    add_option '--init' do |v, opts|
      opts[:init] = v
    end
  end

  def execute
    if options[:init]
      init_world
    else
      list
    end
  end

  def add(name, version)
    open(world_path, 'r+') do |f|
      f << YAML.load(f).tap {|world|
        (world[name] ||= []).tap {|vs|
          vs << version.to_s
        }.uniq!

        f.rewind
      }.to_yaml
    end
  end

  def world_path
    File.join(Gem.user_dir, 'world')
  end

  def world_gems
    YAML.load_file(world_path).inject([]) {|acc, (name, versions)|
      acc + versions.map {|v|
        Gem.source_index.find_name(name, v).sort_by(&:version).last
      }.compact
    }
  end

  def list
    YAML.load_file(world_path).sort_by(&:first).each do |name, versions|
      say "#{name} (#{versions.join(', ')})"
    end
  end

  def init_world
    open(world_path, 'w') do |f|
      f << Gem.source_index.map(&:last).select {|spec|
        spec.dependent_gems.empty?
      }.group_by(&:name).inject({}) {|h, (name, specs)|
        versions = specs.sort_by(&:version).map {|spec| spec.version }
        versions[-1] = Gem::Requirement.default

        h.merge(name => versions.map(&:to_s))
      }.to_yaml
    end
  end
end

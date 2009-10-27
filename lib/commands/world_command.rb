require 'rubygems/command'
require 'rubygems/requirement'
require 'yaml'

class Gem::Commands::WorldCommand < Gem::Command
  Gem.post_install do |installer|
    command = Gem::CommandManager.instance['install']
    name = installer.spec.name

    begin
      if command.get_all_gem_names.include?(name)
        new.add name, command.options[:version]
      end
    rescue Gem::CommandLineError
      # called by 'gem update'
    end
  end

  def initialize
    super 'world', 'Display gems that in your world'

    add_option '--init' do |v, opts|
      opts[:init] = v
    end

    add_option '-e', '--edit' do |v, opts|
      opts[:edit] = v
    end
  end

  def execute
    if options[:init]
      init_world
    elsif options[:edit]
      edit
    else
      list
    end
  end

  def edit
    unless editor = ENV['VISUAL'] || ENV['EDITOR']
      alert_error 'Please set VISUAL or EDITOR variable.'
      terminate_interaction
    end

    system editor, world_path
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
    YAML.load_file(world_path).sort_by {|name, versions|
      name.downcase
    }.each do |name, versions|
      say "#{name} (#{versions.join(', ')})"
    end
  end

  def init_world
    open(world_path, 'w') do |f|
      f << Gem.source_index.map(&:last).select {|spec|
        spec.dependent_gems.empty?
      }.group_by(&:name).inject({}) {|h, (name, specs)|
        versions = specs.map(&:version).sort
        versions[-1] = Gem::Requirement.default

        h.merge(name => versions.map(&:to_s))
      }.to_yaml
    end
  end
end

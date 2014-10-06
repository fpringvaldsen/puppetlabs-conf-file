require 'hocon/config_factory'
require 'hocon/config_value_factory'
require File.expand_path('../../../util/config_saver', __FILE__)

Puppet::Type.type(:conf_setting).provide(:ruby) do
  def self.namevar(section_name, setting)
    "#{setting}"
  end

  def exists?
    conf_file.has_path(setting)
  end

  def create
    value = Hocon::ConfigValueFactory.from_any_ref(resource[:value], nil)
    conf_file_modified = conf_file.with_value(setting, value)
    Puppet::Util::ConfigSaver.save(resource[:path], conf_file_modified)
    @conf_file = nil
  end

  def destroy
    conf_file_modified = conf_file.without_path(setting)
    Puppet::Util::ConfigSaver.save(resource[:path], conf_file_modified)
    @conf_file = nil
  end

  def value
    conf_file.get_value(setting).unwrapped
  end

  def value=(value)
    value = Hocon::ConfigValueFactory.from_any_ref(resource[:value], nil)
    conf_file_modified = conf_file.with_value(setting, value)
    Puppet::Util::ConfigSaver.save(resource[:path], conf_file_modified)
    @conf_file = nil
  end

  def section
    # this method is here so that it can be overridden by a child provider
    resource[:section]
  end

  def setting
    # this method is here so that it can be overridden by a child provider
    resource[:setting]
  end

  def file_path
      resource[:path]
  end

  private
  def conf_file
    if @conf_file.nil? && (not File.exist?(file_path))
      File.new(file_path, "w")
    end
    @conf_file ||= Hocon::ConfigFactory.parse_file(file_path)
  end

end

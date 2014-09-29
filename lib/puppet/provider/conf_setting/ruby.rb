require 'hocon/config_factory'
require 'hocon/config_value_factory'
require File.expand_path('../../../util/config_saver', __FILE__)

Puppet::Type.type(:conf_setting).provide(:ruby) do

  def self.instances
    # this code is here to support purging and the query-all functionality of the
    # 'puppet resource' command, on a per-file basis.  Users
    # can create a type for a specific config file with a provider that uses
    # this as its parent and implements the method
    # 'self.file_path', and that will provide the value for the path to the
    # ini file (rather than needing to specify it on each ini setting
    # declaration).  This allows 'purging' to be used to clear out
    # all settings from a particular ini file except those included in
    # the catalog.
    if self.respond_to?(:file_path)
      # figure out what to do about the separator
      conf_file  = Hocon::ConfigFactory.parse_file(file_path)
      resources = []
      conf_file.section_names.each do |section_name|
        conf_file.get_settings(section_name).each do |setting, value|
          resources.push(
            new(
              :name   => namevar(section_name, setting),
              :value  => value,
              :ensure => :present
            )
          )
        end
      end
      resources
    else
      raise(Puppet::Error, 'Conf_settings only support collecting instances when a file path is hard coded')
    end
  end

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
    # this method is here to support purging and sub-classing.
    # if a user creates a type and subclasses our provider and provides a
    # 'file_path' method, then they don't have to specify the
    # path as a parameter for every conf_setting declaration.
    # This implementation allows us to support that while still
    # falling back to the parameter value when necessary.
    if self.class.respond_to?(:file_path)
      self.class.file_path
    else
      resource[:path]
    end
  end

  def separator
    if resource.class.validattr?(:key_val_separator)
      resource[:key_val_separator] || '='
    else
      '='
    end
  end

  private
  def conf_file
    @conf_file ||= Hocon::ConfigFactory.parse_file(file_path)
  end

end

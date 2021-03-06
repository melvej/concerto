class ConcertoPlugin < ActiveRecord::Base
  attr_accessible :enabled, :gem_name, :gem_version, :installed, :module_name, :name, :source, :source_url

  mattr_accessor :apps_to_mount

  # Method to be called exactly once at app boot
  # Will iterate over all the enabled plugins, and attempt to
  # run their initialization code. This is a hook for plugins
  # to take care of their proper installation, set up configs,
  # set up hooks, and request routing if needed.
  def self.initialize_plugins
    method_name = "initialize_plugin"
    ConcertoPlugin.all.each do |plugin|
      if plugin.enabled?
        if Object.const_defined?(plugin.module_name) 
          mod = plugin.module_name.constantize
          if mod.respond_to? method_name
            mod.method(method_name).call(plugin)
          else 
            logger.warn("Concerto Plugin #{plugin.name} does not respond to "+
                        initialize_plugin + ", skipping initialization.")
          end
        else
          logger.warn("Concerto Plugin #{plugin.name} module (" +
                      plugin.module_name + 
                      ") not found. Skipping initialization.")
        end
      end
    end
  end

  # Used by the plugin initializer to register its own information
  # Options hash takes the same arguments as ConcertoConfig.make_concerto_config
  # except for the plugin_id field.
  def make_plugin_config(config_key, config_value, options={})
    options[:plugin_id] = id
    ConcertoConfig.make_concerto_config(config_key, config_value, options)
  end

  # Requests that the plugin be mounted as a rack app at
  #   Rails.root/url_string
  # The plugin is responsible for setting its own engine name.
  # Should only be called by the plugin during initialization.
  def request_route(url_string, rack_app)
    self.apps_to_mount = self.apps_to_mount || []
    self.apps_to_mount << {:url_string => url_string, :rack_app => rack_app}
  end
end

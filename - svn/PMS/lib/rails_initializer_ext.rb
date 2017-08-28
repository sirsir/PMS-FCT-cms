module Rails
  class Initializer
    # Loads the environment specified by Configuration#environment_path, which
    # is typically one of development, test, or production.
    def load_environment
      silence_warnings do
        return if @environment_loaded
        @environment_loaded = true

        config = configuration
        constants = self.class.constants
        
        if File.exists?(configuration.environment_path)
          eval(IO.read(configuration.environment_path), binding, configuration.environment_path)
        else
          client_config_path = "/#{config.client_folder}/#{config.env_client_code}\\1"
          client_environment_path = configuration.environment_path.gsub(/(\/config\/)/, client_config_path)
          eval(IO.read(client_environment_path), binding, client_environment_path)
        end
        
        (self.class.constants - constants).each do |const|
          Object.const_set(const, self.class.const_get(const))
        end
      end
    end
  end
end

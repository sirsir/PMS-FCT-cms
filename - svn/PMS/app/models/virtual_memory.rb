class VirtualMemory

  DEFAULT_FORMAT = :Marshal
  
  class << self
    #   VirtualMemory.store(group, id, object, format = :Marshal) -> a_file
    #   
    # Store the object to the VM
    #  require 'virtual_memory'
    #
    #  a = [1,2,3,4]
    #  b = [3,4,5,6]
    #  c = [5,4,3,2,1]
    #  d = [a,1,b,2,c,4]
    #  
    #  VirtualMemory.store(:console, 0, d, :Marshal) #=> stored_file
    #  VirtualMemory.store(:console, 0, d, :YAML)    #=> stored_file
    def store(group, id, object, format = DEFAULT_FORMAT)
      raise 'Storing !ruby/object: to VirtualMemory is prohibited' if object.inspect =~ /#<\w+ id: \d+.*>/

      File.open( file_name(group, id, format), 'w' ) do |file|
        format.to_s.constantize.dump( object, file )
      end
    end

    #   VirtualMemory.load(group, id, format = :Marshal) -> an_object
    #
    # Restore the object from the VM
    #  require 'virtual_memory'
    #
    #  a = [1,2]
    #  b = [3,4]
    #  c = [5,a,3,b,1]
    #  
    #  VirtualMemory.store(:console, 0, b, :Marshal)  #=> stored_file
    #  VirtualMemory.load(:console, 0, :Marshal )     #=> [3,4]
    #
    #  VirtualMemory.store(:console, 0, c, :YAML)     #=> stored_file
    #  VirtualMemory.load(:console, 0, :YAML )        #=> [5,[1,2],3,[3,4],1]
    def load(group, id, format = DEFAULT_FORMAT)
      vm = begin
        File.open( file_name(group, id, format), 'r' ) do |file|
          format.to_s.constantize.load( file )
        end if exists?(group, id, format)
      rescue Exception => ex
        Rails.logger.error(ex)
        nil
      end
      vm || {}
    end

    #   VirtualMemory.exists?(group, id, format = :Marshal) -> boolean
    #
    # Check if the VM exists
    #  require 'virtual_memory'
    #
    #  b = [3,4]
    #  
    #  VirtualMemory.store(:console, 0, b, :Marshal)  #=> stored_file
    #  VirtualMemory.exists?(:console, 0, :Marshal )  #=> true
    #
    #  VirtualMemory.exists?(:console, 0, :YAML )     #=> false
    def exists?(group, id, format = DEFAULT_FORMAT)
      File.exists?( file_name(group, id, format) )
    end

    #   VirtualMemory.path -> string
    # Returns default path for storing the vm files
    #   VirtualMemory.path = C:/pms/tmp/cache/vm
    def path
      @@path ||= File.join(RAILS_ROOT, 'tmp', 'cache', 'vm')
    end

    #   VirtualMemory.clear(group)
    # Removed all stored cached file for the specified group
    #   VirtualMemory.clear(:view_cache)
    #
    # Removed all stored cached file for the specified group and id
    #   VirtualMemory.clear(:view_cache, 123)
    def clear(group, id = '*', format = DEFAULT_FORMAT, options = {})
      defaults = {
        :block_size => 100,
        :async => false
      }
      options = defaults.merge(options)
      
      if options[:async]
        object = {
          :group => group,
          :id => id,
          :format => format,
          :options => options
        }
        
        store('_async', Time.now.hash, object)
      else
        case id
        when Array
          cleared = false
          (0...id.size).step(options[:block_size]) do |i|
            ids = id[i...i+options[:block_size]].join(',')
            cleared |= clear(group, "{#{ids}}", format)
          end

          cleared
        else
          list = Dir.glob(file_name(group, id, format))
          FileUtils.rm_f list unless list.empty?

          !list.empty?
        end
      end
    end

    #   VirtualMemory.check_expiration(ht)  #=> nil or int
    # Clear hash if it's out of date
    def check_expiration(ht, cache_expiration = 0)
      cache_expiration = ht[:cache_expiration] ||= (cache_expiration.to_i == 0 ? Rails.configuration.cache_expiration : cache_expiration)
      
      if (ht[:updated_at] || Time.at(0)) < Time.now - cache_expiration
        ht.clear 
        
        ht[:updated_at] = Time.now
        ht[:cache_expiration] = cache_expiration
      end
    end
    
    private

    # Formats : :Marshal, :YAML, :JSON
    def file_name(group, id, format = DEFAULT_FORMAT)
      File.join(VirtualMemory.path, group.to_s.underscore, "#{group.to_s.underscore}_#{id.to_s.underscore}.#{format.to_s.downcase}")
    end
  end
end

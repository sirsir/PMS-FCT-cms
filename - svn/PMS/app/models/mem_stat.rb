class MemStat
  OBJECT_SPACE_COUNT = 1000 # occurrence
  TASK_LIST_MEM_SIZE = 2**25 # Bytes

  class << self
    def module_names
      @module_names ||= std_object_types + app_models
    end

    def create_object_chart(rails_port, mem_type, session_id)
      vm = VirtualMemory.load(:mem_stat, rails_port)

      data = []

      case mem_type
      when 'object_allocation'
        object_spaces = vm[:object_space]
        module_names = object_space_module_names(object_spaces)

        timestamps = object_spaces.keys.sort

        data = module_names.collect do |m|
          {
            :name => m.to_s,
            :values => timestamps.collect{|ts| object_spaces[ts][m] || 0 }
          }
        end if timestamps.size > 1
      when 'task_allocation'
        task_lists = vm[:task_list]
        image_names = task_list_image_names(task_lists)

        timestamps = task_lists.keys.sort

        data = image_names.collect do |n|
          {
            :name => n.to_s,
            :values => timestamps.collect{|ts| task_lists[ts].select{|t| "#{t[:image_name]}[#{t[:pid]}]" == n }.collect{|t| t[:mem_usage] } }.flatten
          }
        end if timestamps.size > 1
      end

      image_path = File.join(Rails.root, 'tmp', 'cache', 'img', "memory_chart_#{mem_type}_#{session_id.first(5)}.png")

      write_chart(image_path, data)

      image_path
    end
    
    private
    
    def std_object_types
      %w(
      Array
      Float
      Hash
      Regexp
      String
      ).collect{|m| m.constantize }
    end

    def app_models
      filenames = Dir.glob(File.join(Rails.root, 'app', 'models', '*.rb'))
      filenames.collect{|f_name| File.basename(f_name, '.rb')}.collect{|f| f.classify.constantize }
    end

    def write_chart(image_path, data, top = 10)
      g = Gruff::Line.new('800x300')

      font_size = 12
      margin = 5
      line_width = 1

      # General
      g.margins = margin
      g.theme = g.theme_37signals

      # Title
      g.title_font_size = 0

      # Legend
      g.legend_font_size = font_size
      g.legend_box_size = margin
      g.legend_margin = margin

      # Marker
      g.marker_font_size = font_size

      # Line
      g.line_width = line_width
      g.dot_radius = line_width

      data = data.sort_by{|d| d[:values].collect{|v| v.to_i }.max }.last(top).reverse
      data.each{|d| g.data(d[:name], d[:values]) }
      
      g.write(image_path)
    end

    def object_space_module_names(object_space)
      module_names = object_space.values.collect{|o| o.keys }.flatten
      module_names.sort!{|a, b| a <=> b }
      module_names.uniq!

      module_names
    end

    def task_list_image_names(task_list)
      image_names = task_list.values.flatten.collect{|t| "#{t[:image_name]}[#{t[:pid]}]" }
      image_names.sort!{|a, b| a <=> b }
      image_names.uniq!

      image_names
    end
  end

  def initialize(rails_port)
    @rails_port = rails_port

    update_object_history
  end

  def current_objects
    module_count = {}
    MemStat.module_names.each do |module_name|
      module_count[module_name.to_s] = ObjectSpace.each_object(module_name){|obj| }
    end
    
    module_count.delete_if{|key, v| v < OBJECT_SPACE_COUNT }
  end

  def object_history
    @object_history
  end
  
  def system_memory
    @system_memory ||= `SYSTEMINFO`.split("\n").select{|s| s =~ /Memory/} \
      .collect{|s|
        s.split(/: /)
      }
  end
  
  def current_tasks
    list = `TASKLIST`.split("\n").select{|s| !s.strip.empty? }
    lines = list[1].to_s.split(/ /).collect{|l| l.size }
    
    [list[2...list.size]].flatten.compact.collect{|t|
      task = {}
      pos = 0

      task[:image_name] = t[pos...lines[0]].strip
      pos += lines[0] + 1

      task[:pid] = t[pos...pos+lines[1]].strip.to_i
      pos += lines[1] + 1

      task[:session_name] = t[pos...pos+lines[2]].strip
      pos += lines[2] + 1
      
      task[:session_no] = t[pos...pos+lines[3]].strip
      pos += lines[3] + 1

      task[:mem_usage] = t[pos...pos+lines[4]].gsub(/[^\d]/, '').to_i * 1024
      
      task if task[:mem_usage] > TASK_LIST_MEM_SIZE
    }.compact.sort_by{|t| t[:mem_usage] }.reverse
  end

  def current_cache
    folders = Dir.glob("#{RAILS_ROOT}/tmp/cache/vm/*").select{|f| f.split('/').last !~ /^_/ }
    
    [folders].flatten.compact.collect{|f|
      vm_group = f.split('/').last.to_sym
      file_list = `ls -l #{f} | awk '{print $5}'`.split("\n")
      {
        :name => vm_group.to_s.titleize.gsub(/^(.)cr /, '\1CR '),
        :vm_group => vm_group,
        :size => file_list.collect{|s| s.to_i }.inject{|n,s| n+=s}.to_i,
        :file_count => file_list.size - 1
      }
    }
  end

  private

  def update_object_history
    GC.start
    
    vm = VirtualMemory.load(:mem_stat, @rails_port)

    new_object_space = current_objects
    new_task_list = current_tasks

    timestamp = Time.now
    check_point = timestamp.ago(60*60*24*2)
    
    vm[:object_space] ||= {}
    vm[:object_space].delete_if {|k, v| k < check_point }
    vm[:object_space][timestamp] = new_object_space
    
    vm[:task_list] ||= {}
    vm[:task_list].delete_if {|k, v| k < check_point }
    vm[:task_list][timestamp] = new_task_list


    VirtualMemory.store(:mem_stat, @rails_port, vm)

    @object_history = vm
  end

end

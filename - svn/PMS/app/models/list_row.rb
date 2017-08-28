class ListRow < Row

  def clear_cache
    if super
      unless self.used_by.nil?
        #~ ToDo: Clear recursively row by dependency
        #  used_by_rows = self.used_by(true)
        #  used_by_rows.each{|r| r.clear_cache } unless used_by_rows.empty?
        
        screens = self.screen.dependencies(true)
        row_ids = screens.collect{|s| s.row_ids }.flatten
        
        VirtualMemory.clear(:field_cache, row_ids, :marshal, :async => true)
        VirtualMemory.clear(:view_cache, row_ids.collect{|r_id| "row_#{r_id}" }, :marshal, :async => true)
        VirtualMemory.clear(:row_cache, row_ids, :marshal, :async => true)
      end
      
      true
    end
  end
end

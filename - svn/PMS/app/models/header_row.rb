class HeaderRow < Row
	has_many :rows, :foreign_key => 'row_id', :order => 'id', :dependent => :destroy

	alias_attribute :revision_rows, :rows
	alias_attribute :revision_row_ids, :row_ids

	class << self
		def save(params)
			row_attr = {}
			row_attr[:screen_id] = params.delete(:screen_id)
			row_attr[:remark] = params.delete(:remark)

			row = HeaderRow.new(row_attr)
			cells = params.delete(:cells) || {}

			# Force saving cells for searchable field
			field_ids_of_searchable = params[:field_ids_of_searchable]
			field_ids_of_searchable.each do |f_id|
				cells[f_id] = '' if params["screen_quick_search_text_#{f_id}"].to_s.empty?
			end unless field_ids_of_searchable.nil?

			header_custom_field_ids = row.screen.fields.collect{|f| f.custom_field_ids }.flatten
			revision_custom_fields = {}
			cells.each_key do |k|
				revision_custom_fields[k] = cells.delete(k) unless header_custom_field_ids.include?(k.to_i)
			end

			cells.each do |field_id, value|
				cell = Cell.new(:field_id => field_id, :value => value)
				row.cells << cell
				row.load_cell_hash(cell)
			end

			#clone revision
			revision_row = RevisionRow.new()
			revision_row.header_row = row
			revision_row.screen = row.screen.revision_screen
			revision_row.value = {:rev_no => row.latest_revision_no + 1}
			revision_row.remark = ''

			data_fields = revision_row.screen.data_fields
			ref_attr_fields = revision_row.screen.fields.select{|f|
				(f.is_a?(Fields::ReferenceAttribute) || f.is_a?(Fields::CodeCombindedReferenceAttribute)) &&
          !f.read_only?
			}

			data_fields.each do |f|
				cell_value = revision_custom_fields[f.custom_field.id.to_s] || f.custom_field.evaluate_default_value({:row => revision_row, :field => f})
				cell = Cell.new(:field_id => f.custom_field_id, :value => cell_value)
				revision_row.cells << cell
				revision_row.load_cell_hash(cell)
			end

			ref_attr_fields.each do |f|
				reference_field = Field.find(f.reference_field_id)

				next unless reference_field.is_mandatory? && reference_field.display_in_form?

				source_field = Field.find(f.source_field_id)

				cell = revision_row.cell(reference_field.custom_field_id)

				reference_row_id = CustomFields::Reference.cell_ref_row_id(cell.value)
				reference_row = Row.find(reference_row_id)

				cell_value = ''
				case f
				when Fields::ReferenceAttribute
					if source_field.is_a?(Fields::Data)
						ref_cell = reference_row.cell(source_field.custom_field_id)
						cell_value = ref_cell.nil? ? '' : ref_cell.to_html
					else
						cell_value = source_field.evaluate_value(reference_row)
					end
				when Fields::CodeCombindedReferenceAttribute
					raise 'Missing implementation'
        end if !reference_row.nil?

        cell.value[f.id.to_s] = cell_value
      end
        
      ActiveRecord::Base.transaction do
        row.cells.each do |c|
          case c.field
          when CustomFields::AutoNumbering
            CustomFields::AutoNumbering.set_cell_temp_text(c.value)
          end
        end

        if row.save && row.cells.all? {|c| c.save }
          if revision_row.save && revision_row.cells.all? {|c| c.save }
            #~ Do Nothing
          else
            revision_row.errors.full_messages.each{|msg| row.errors.add(msg) }
          end
        end
					
        raise ActiveRecord::Rollback unless row.errors.empty?

        row.cells.each do |c|
          case c.field
          when CustomFields::AutoNumbering
            auto_numbering_text = CustomFields::AutoNumbering.increase(c.field_id, row.cells)
            CustomFields::AutoNumbering.set_cell_text(c.value, auto_numbering_text)
            c.save
          end
        end
      end

      row
    end
  end

  def clear_cache(options = {})
    if super
      defaults = {
      }

      options = defaults.merge(options)

      self.latest_revision.clear_cache(options) unless self.latest_revision.nil?

      true
    end
  end

  def row
    nil
  end

  def operation_url_options
    {
      :controller => :revision_rows,
      :action => :index
    }
  end

  def relation_url_options
    {
      :controller => :revision_rows
    }
  end

  def latest_revision
    revision_rows.last
  end

  def latest_revision_no
    latest_revision.nil? ? -1 : latest_revision.rev_no
  end

  def updated_at(row_id_chain = [])
    @updated_at ||= begin
			return nil if row_id_chain.include?(self[:id])

			updated_dates = [super(row_id_chain)]

			revision_row = self.latest_revision
			updated_dates << revision_row.updated_at(row_id_chain) unless revision_row.nil?

			updated_dates.compact.max
		end
	end
end


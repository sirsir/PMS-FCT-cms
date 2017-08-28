module CustomFields
  class FileType
    attr_accessor :id
    attr_accessor :name
    attr_accessor :descr

    class << self

      #   CustomFields::FileType.text_type_collection -> array
      # Get array that contain #CustomFields::FileType
      # each custom field's object was create from text type
      #   CustomFields::FileType.text_type_collection #=> [#CustomFields1, #CustomFields2, ...]
      def text_type_collection
        text_types.collect{|k,v| v}.sort{|a, b| a.id <=> b.id}
      end

      #   CustomFields::FileType.image_type_collection -> array
      # Get array that contain #CustomFields::FileType
      # each custom field's object was create from image type
      #   CustomFields::FileType.image_type_collection #=> [#CustomFields1, #CustomFields2, ...]
      def image_type_collection
        image_types.collect{|k,v| v}.sort{|a, b| a.id <=> b.id}
      end

      private

      def text_types
        @@cached_text_types ||= {}

        list_text_type.each do |k, v|
          cf = CustomFields::FileType.new
          cf.id = k.to_s
          cf.name = k
          cf.descr = v

          @@cached_text_types[k.to_s] = cf
        end if @@cached_text_types .empty?

        @@cached_text_types
      end

      def image_types
        @@cached_image_types ||= {}

        list_image_type.each do |k, v|
          cf = CustomFields::FileType.new
          cf.id = k.to_s
          cf.name = k
          cf.descr = v

          @@cached_image_types[k.to_s] = cf
        end if @@cached_image_types .empty?

        @@cached_image_types
      end

      def list_text_type
        {
          :csv => '.csv',
          :txt => '.txt',
          :html => '.html',
          :xml => '.xml'
        }
      end

      def list_image_type
        {
          :gif => '.gif',
          :jpg => '.jpg',
          :png => '.png',
          :tiff => '.tiff'
        }
      end
    end
  end
end

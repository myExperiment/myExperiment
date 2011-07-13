
class ActiveRecord::Base

  def self.has_previews

    self.class_eval do

      belongs_to :preview

      def image
        preview.image_blob.data if preview && preview.image_blob
      end

      def svg
        preview.svg_blob.data if preview && preview.svg_blob
      end

      def image=(x)

        self.preview = Preview.new if self.preview.nil?
        self.preview.image_blob = ContentBlob.new if self.preview.image_blob.nil?

        self.preview.image_blob.data = x
      end

      def svg=(x)

        self.preview = Preview.new if self.preview.nil?
        self.preview.svg_blob = ContentBlob.new if self.preview.svg_blob.nil?

        self.preview.svg_blob.data = x
      end

      after_save { |ob|
      
        p = ob.preview

        if p

          ib = p.image_blob
          sb = p.svg_blob

          if ib && ib.data_changed?
            ib.save
            ob.preview.clear_cache
          end

          if sb && sb.data_changed?
            sb.save
            ob.preview.clear_cache
          end
          
          p.save
        end
      }
    end
  end
end


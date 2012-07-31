
class ActiveRecord::Base

  def self.has_previews

    self.class_eval do

      belongs_to :preview, :dependent => :destroy, :autosave => true

      def image
        preview.image_blob.data if preview && preview.image_blob
      end

      def svg
        preview.svg_blob.data if preview && preview.svg_blob
      end

      def image=(x)

        x = x.read if x.respond_to?(:read)

        self.preview = Preview.new if self.preview.nil?
        self.preview.image_blob = ContentBlob.new if self.preview.image_blob.nil?

        self.preview.image_blob.data = x
      end

      def svg=(x)

        x = x.read if x.respond_to?(:read)

        self.preview = Preview.new if self.preview.nil?
        self.preview.svg_blob = ContentBlob.new if self.preview.svg_blob.nil?

        self.preview.svg_blob.data = x
      end
    end
  end
end


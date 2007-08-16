require 'qrcode'

ActionView::Helpers::AssetTagHelper::register_javascript_include_default('qrcode')

ActionView::Base.send(:include, QRCode::QRCodeHelper)
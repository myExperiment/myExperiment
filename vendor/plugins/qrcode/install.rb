require 'fileutils'

here = File.dirname(__FILE__)
there = defined?(RAILS_ROOT) ? RAILS_ROOT : "#{here}/../../.."

puts "Installing QRCode..."
FileUtils.cp("#{here}/media/qrcode.js", "#{there}/public/javascripts/")
puts "QRCode has been installed."
puts
puts IO.read(File.join(File.dirname(__FILE__), 'README'))

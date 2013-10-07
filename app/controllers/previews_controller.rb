# myExperiment: app/controllers/previews_controller.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'RMagick'

class PreviewsController < ApplicationController

  before_filter :find_context

  def show

# FIXME: This is the temporary workaround for the issue described in 
#        http://dev.mygrid.org.uk/issues/browse/MYEXP-67 
#
#   auth = request.env["HTTP_AUTHORIZATION"]
#   user = current_user

#   if auth and auth.starts_with?("Basic ")
#     credentials = Base64.decode64(auth.sub(/^Basic /, '')).split(':')
#     user = User.authenticate(credentials[0], credentials[1])

#     if user.nil?
#       render :nothing => true, :status => 401
#       response.headers['WWW-Authenticate'] = "Basic realm=\"#{Conf.sitename} REST API\""
#       return
#     end
#   end

    if @context.preview.nil?
      render :nothing => true, :status => 404
      return
    end

# FIXME: The other part of the temporary workaround decribed in
#        http://dev.mygrid.org.uk/issues/browse/MYEXP-67 
#
#   if @context.respond_to?("versioned_resource")
#     auth_object = @context.versioned_resource
#   else
#     auth_object = @context
#   end

#   if Authorization.check('view', auth_object, user) == false
#     render :nothing => true, :status => 401
#     response.headers['WWW-Authenticate'] = "Basic realm=\"#{Conf.sitename} REST API\""
#     return
#   end

    type = params[:id]

    mime_type = nil

    case type

      when 'full';   source = 'image'; size = nil; mime_type = 'image/jpeg'
      when 'medium'; source = 'image'; size = 500; mime_type = 'image/jpeg'
      when 'thumb';  source = 'image'; size = 100; mime_type = 'image/jpeg'
      when 'svg';    source = 'svg';   size = nil; mime_type = 'image/svg+xml'
      else
        render(:inline => 'Bad preview type', :status => 400)
        return
    end

    content_blob = nil

    case source
      when 'image'
        content_blob = @context.preview.image_blob
        if content_blob.nil? && @context.preview.svg_blob # If no image, but an SVG, render a JPG from the SVG.
          content_blob = @context.preview.svg_blob
          mime_type = 'image/svg+xml' if size.nil? # Just show the SVG when "full" image is requested
        end
      when 'svg';   content_blob = @context.preview.svg_blob
    end

    if content_blob.nil?
      render :nothing => true, :status => 404
      return
    end

    file_name = @context.preview.file_name(type)

    send_cached_data(file_name, :type => mime_type, :disposition => 'inline') {

      data = content_blob.data

      if size

        img = Magick::Image.from_blob(data).first
        img = img.change_geometry("#{size}x#{size}>") do |c, r, i| i.resize(c, r) end

        result = Magick::Image.new(img.columns, img.rows)
        result = result.composite(img, 0, 0, Magick::OverCompositeOp)
        result.format = "jpg"

        data = result.to_blob
      end

      data
    }
  end

  private

  def find_context
    @context = extract_resource_context(params)
    if @context.nil?
      render_404("Resource not found.")
    elsif params[:version]
      @context = @context.find_version(params[:version])
      if @context.nil?
        render_404("Resource version not found.")
      end
    end
  end
end

class LicenseAttributesController < ApplicationController
  before_filter :login_required
  before_filter :find_license_attribute, :only => [:index]

  def destroy
      LicenseAttribute.find(params[:id]).destroy
  end

  
  protected
  
  def find_license_attribute
    begin
      @license_attribute = LicenseAttribute.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404("License Attribute not found.")
    end
  end
  
end

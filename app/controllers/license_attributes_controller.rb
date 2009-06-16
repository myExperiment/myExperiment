class LicenseAttributesController < ApplicationController
  before_filter :login_required
  before_filter :find_license_attribute, :only => [:index]
  
  def destroy
    @license_attribute = LicenseAttribute.find(params[:id])
    @license_attribute.destroy

    respond_to do |format|
      format.html { redirect_to license_url(@license_attribute.license) }
    end
  end

  
  protected
  
  def find_license_attribute
    begin
      @license_attribute = LicenseAttribute.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("License Attribute not found", "is invalid")
    end
  end
  
end

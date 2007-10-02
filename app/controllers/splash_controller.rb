class SplashController < ApplicationController

  def index

    if logged_in?
      redirect_to :controller => 'users'
    end

  end
end

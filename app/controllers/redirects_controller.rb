
class RedirectsController < ApplicationController

  # Antoon's survey
  def exercise
    redirect_to 'http://www.cs.man.ac.uk/~goderisa/exercise'
  end
  
  # For Antoon
  def google
    redirect_to 'http://www.google.com/coop/cse?cx=006491099109873764573%3Ahtaex4vgqqg'
  end

end


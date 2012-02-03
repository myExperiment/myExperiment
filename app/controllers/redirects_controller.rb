
class RedirectsController < ApplicationController

  # For Antoon
  def google
    redirect_to 'http://www.google.com/coop/cse?cx=006491099109873764573%3Ahtaex4vgqqg'
  end

  # For Antoon
  def benchmarks
    redirect_to 'http://www.myexperiment.org/packs/10'
  end
end


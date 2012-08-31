class FsController < CatalogController 
  def on
    session[:fs] = 1
  end

  def off
    session[:fs] = 0
  end

  def toggle
    if session.has_key? :fs and session[:fs] == 1
      off
    else
      on
    end
  end
end

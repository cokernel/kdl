class PagesController < CatalogController
  def about
  end

  def partners
  end

  def recent_changes
  end

  def statistics
  end

  def visitors_overview
    render :layout => false
  end
end

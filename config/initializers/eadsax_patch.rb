require 'eadsax'

module Eadsax
  class Did
    element :dao, :value => :entityref, :as => :dao_link
    elements :container, :value => :label, :as => :container_labels
  end

  class Container
    element :container, :value => :label, :as => :container_label
  end

  class ListTwo
    include SAXMachine
    elements :item, :as => :items
  end

  class Scopecontent
    element :list, :class => Eadsax::ListTwo
  end
end

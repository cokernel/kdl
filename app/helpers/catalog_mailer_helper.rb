module CatalogMailerHelper
  def sanitize_question(question)
    question.gsub!(/\[([^\]]+)\].*\[\/\1\]/, '')
    question.gsub!(/\[([^\]]+)=.*\].*\[\/\1\]/, '')
    sanitize(question, :tags => [])
  end
  
  def sanitize_phone(phone)
    phone.gsub(/[^0-9\-+*#p\(\) ]/, '')
  end
end

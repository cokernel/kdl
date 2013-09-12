module CatalogMailerHelper
  def sanitize_question(question)
    question.gsub!(/\[([^\]]+)\].*\[\/\1\]/, '')
    sanitize(question, :tags => [])
  end
end

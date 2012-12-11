class CatalogMailer < ActionMailer::Base
  def contact_us(repo, document, patron)
    recipients repo['email']
    bcc        'm.slone@uky.edu'
    from       "webmaster@eris.uky.edu"
    subject    "Patron request regarding KDL item #{document[:id]}"
    body       :repo => repo, :document => document, :patron => patron
  end
end
# CatalogMailer.deliver_contact_us(document...)

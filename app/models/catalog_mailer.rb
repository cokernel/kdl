class CatalogMailer < ActionMailer::Base
  add_template_helper(CatalogMailerHelper)
  def contact_us(repo, document, patron)
    recipients repo['email']
    bcc        ['m.slone@uky.edu', 'sarah.dorpinghaus@uky.edu']
    from       "webmaster@eris.uky.edu"
    subject    "Patron request regarding KDL item #{document[:id]}"
    body       :repo => repo, :document => document, :patron => patron
  end
end
# CatalogMailer.deliver_contact_us(document...)

# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_kdl_session',
  :secret      => '0670bbd725c6c8235c56728ab2be884b35a4ddccea00ef4728597d1fafbf9657daae6a9222ece17008914351943a2d99dcd1c7dd3050792bd469433bd61ec0cc'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

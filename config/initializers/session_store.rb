# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_empty2311_session',
  :secret      => 'dc9f8b03a18fc2b7fa858bf660d9685f1637ed67c1ff0fd5c39978ec2f22ccca8201b32d89aeada76722b4ee5fa3df9df7400b37995636876a7140f0382231ef'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

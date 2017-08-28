# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Force Webrick to listen on multiple ports
# config.first_port = 3000
config.listening_ports = 1
# config.offline = false

# Support
# Email address for posting message to the PMS support team
config.support_email = 'danzler.s@tse.co.jp'

# Set if MemStat should collect memory usage on every request, for every interval
# The value is in the range 0 ~ 60 minutes. (0 is for Disabled)
# config.mem_state_interval = 10

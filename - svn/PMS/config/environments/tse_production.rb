# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Force Webrick to listen on multiple ports
# config.first_port = 3000
config.listening_ports = 1

# Reserved ports for background processes. The index can
# be specified in two directions, from first->last (0..listening_ports-1)
# and from first<-last (-1..-listening_ports).
#
# If there is only one listing port; this function will be ignored.
config.reserved_ports = {
  :report_request => -1
}

# Specify the list of IP addresses to grant access the application
# Leave the list empty to allow all
# config.firewall = %w(192.168.0.0/24)

# When opening the index page with out any filtering, the system
# will fetch only the rows that have been updated since the last
# specified months (default last 1 month)
# config.index_default_updated_at_filter = 1

# Force all request to the offline.html page
# Turn this on when performing maintenance task (restart is required)
# config.offline = false

# Specify the start of the Accounting date (YYYY/mm/dd).
# Only the month is what need to be consider, leave the date 01 and year 2000
config.null_date = '2000/03/01'

# Specify how long to preserve the cached values
# The setting are in seconds (60*60 = 1hr)
# config.cache_expiration = 60*60

# System information
# config.system_name = 'pms',
# config.system_descr = 'Project Management System'
# config.client_name = 'Thai Software Engineering Co.,Ltd.'
# config.client_code = 'tse'
# config.logo_file_name = 'logo.png'

# Subverion Repository
# config.svn_client_mod5_code = 'bd5a2cb40637623177295aed22db25f9'

# Support
# Email address for posting message to the PMS support team
# config.support_email = 'pms_support@tse.in.th'

# Set if MemStat should collect memory usage on every request, for every interval
# The value is in the range 0 ~ 60 minutes. (0 is for Disabled)
# config.mem_state_interval = 10

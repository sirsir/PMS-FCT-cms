# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = false
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# Force Webrick to listen on multiple ports
# config.first_port = 3000
# config.listening_ports = 1

# Reserved ports for background processes. The index can
# be specified in two directions, from first->last (0..listening_ports-1)
# and from first<-last (-1..-listening_ports).
#
# If there is only one listing port; this function will be ignored.
# config.reserved_ports = {
#   :report_request => 0
# }

# When opening the index page with out any filtering, the system
# will fetch only the rows that have been updated since the last
# specified months (default last 1 month)
# config.index_default_updated_at_filter = 1

# Force all request to the offline.html page
# Turn this on when performing maintenance task (restart is required)
# config.offline = false

# Specify the start of the Accounting date (YYYY/mm/dd).
# Only the month is what need to be consider, leave the date 01 and year 2000
# config.null_date = '2000/01/01'

# Specify how long to preserve the cached values
# The setting are in seconds (60*60 = 1hr)
# config.cache_expiration = 60*60

# System information
# config.system_name = 'pms',
# config.system_descr = 'Project Management System'
config.client_name = 'Template'
config.client_code = '_template'
# config.logo_file_name = 'logo.png'

# Subverion Repository
# config.svn_client_mod5_code = 'bd5a2cb40637623177295aed22db25f9'

# Support
# Email address for posting message to the PMS support team
# config.support_email = 'pms_support@tse.in.th'

# Set if MemStat should collect memory usage on every request, for every interval
# The value is in the range 0 ~ 60 minutes. (0 is for Disabled)
# config.mem_state_interval = 10

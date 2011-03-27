# StonewallActionProtection

require  'action_controller'

ActionController::Base.class_eval do
  include StandardPermissions
end

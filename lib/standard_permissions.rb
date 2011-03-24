module StandardPermissions
  def self.included(base)
    base.class_eval{
      class_inheritable_accessor :stonewall_map
      extend StandardPermissions::ClassMethods

      before_filter :set_authorizing_resource
      before_filter :check_permissions
    }
    base.send(:stonewall_map=, @stonewall_map)
  end
  @stonewall_map = HashWithIndifferentAccess.new
  @stonewall_map.merge!({
    :create => :create,
    :new => :create,
    :index => :read,
    :show => :read,
    :edit => :update,
    :update => :update,
    :destroy => :delete
  })

  module ClassMethods
    def update_stonewall_map(acts={})
      stonewall_map.merge!(acts).stringify_keys!
    end
    def authorizing_resource_method(meth)
      @authorizing_resource_method = meth
    end
  end

  private
  def set_authorizing_resource
    authorizing_resource_method = self.class.instance_variable_get(:@authorizing_resource_method)
    return true unless authorizing_resource_method
    @authorizing_resource = self.send(authorizing_resource_method)
  end

  def check_permissions
    if current_user
      return true unless @authorizing_resource
      stonewall_action = self.class.stonewall_map[params[:action]].to_s
      stonewall = @authorizing_resource.class.stonewall
      action_keys = stonewall.actions.keys
      return true unless !stonewall_action.blank? &&
          (action_keys.any?{|a| a == stonewall_action || a == stonewall_action.to_sym } || stonewall.actions[stonewall_action])
      if !current_user.send("may_#{stonewall_action}?",@authorizing_resource)
        respond_to do |format|
          format.html{
            flash[:alert] = "Sorry, but you're not authorized to access '#{action_name.humanize} #{controller_name.humanize}.'"
            redirect_to my_panes_path and return
          }
          format.any { render :text => '' and return }
        end
      end
    end
  end
end

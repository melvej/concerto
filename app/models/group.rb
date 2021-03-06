class Group < ActiveRecord::Base
  has_many :feeds
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships, :conditions => ["memberships.level > ?", Membership::LEVELS[:pending]]
  has_many :screens, :as => :owner

  # Scoped relation for members and pending members
  has_many :all_users, :through => :memberships, :source => :user, :conditions => ["memberships.level != ?", Membership::LEVELS[:denied]]

  # Scoped relations for leaders
  has_many :leaders, :through => :memberships, :source => :user, :conditions => {"memberships.level" => Membership::LEVELS[:leader]}  

  # Validations
  validates :name, :presence => true, :uniqueness => true

  # Test if a user is part of this group
  def has_member?(user)
    users.include?(user)
  end

  # Test if a user has requested membership in this group
  def made_request?(user)
    all_users.include?(user)
  end

  # Test if a user has a certain permission at a level within a group.
  # Sample usage: user_has_permissions?(user, :supporter, :screen, [:subscribe, :all])
  # will test if the `user` has either :all or :subscribe permissions as a supporter in
  # the screen permission type of the current group.
  def user_has_permissions?(user, level, type, permissions)
    return false if user.nil?

    m = Membership.where(:user_id => user, :level => Membership::LEVELS[level]).first
    return false if m.nil?
    return false unless m.perms.include?(type)

    permissions = [permissions] if permissions.is_a? Symbol
    permissions.each do |p|
      return true if m.perms[type] == p
    end
    return false
  end
end

class User < ActiveRecord::Base
  #attr_accessible :email, :username, :password, :password_confirmation
  attr_accessor :password, :password_confirmation, :new_password
  before_save :encrypt_password
  before_create :default_values

  validates_confirmation_of :password, :on => :create
  #validates_presence_of :password, :on => :create
  validates_presence_of :email, :date_of_birth, :on => :create

  validates_presence_of :username, :on => :create
  validates_presence_of :empcode, :on => :create

  validates_uniqueness_of :empcode, :on => :create
  
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }

  validates_uniqueness_of :email, :on => :create

  validates_uniqueness_of :username, :on => :create
  #  validates_presence_of :email, :on => :create
  #  validates_presence_of :username, :on => :create
  #  validates_uniqueness_of :email, :on => :create
  #  validates_uniqueness_of :username, :on => :create
  #validates_confirmation_of :new_password, :if => Proc.new {|user| !user.new_password.nil? && !user.new_password.empty? }
  
  def initialize(attributes = {})
    super # must allow the active record to initialize!
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def default_values
    self.status = 1    
    self.role = 6 if self.role.nil?
    self.deleted = 0
    self.date_added = Time.now
  end  

  def self.authenticate(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    else
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret("#{empcode}@123", password_salt)
    end
  end
  
  def self.authenticate_by_email(email, password)
    user = find_by_email(email)
   # abort(user.to_a.to_s)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def self.authenticate_by_username(username, password)
    user = find_by_username(username)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end
end
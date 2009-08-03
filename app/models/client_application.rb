require 'oauth'
class ClientApplication < ActiveRecord::Base
  belongs_to :user
  has_many :tokens,:class_name=>"OauthToken"
  has_many :permissions,
           :class_name => "KeyPermission",
           :order => "key_permissions.for",
           :dependent => :destroy
  belongs_to :creator,
             :class_name => "User",
	     :foreign_key => "creator_id"
  validates_presence_of :name,:url,:key,:secret
  validates_uniqueness_of :key
  before_validation_on_create :generate_keys
  
  def self.find_token(token_key)
    token=OauthToken.find_by_token(token_key, :include => :client_application)
    logger.info "Loaded #{token.token} which was authorized by (user_id=#{token.user_id}) on the #{token.authorized_at}"
    return token if token.authorized?
    nil
  end
  
  def self.verify_request(request, options = {}, &block)
    begin
      signature=OAuth::Signature.build(request,options,&block)
      logger.info "Signature Base String: #{signature.signature_base_string}"
      logger.info "Consumer: #{signature.send :consumer_key}"
      logger.info "Token: #{signature.send :token}"
      return false unless OauthNonce.remember(signature.request.nonce,signature.request.timestamp)
      value=signature.verify
#      value=true
      logger.info "Signature verification returned: #{value.to_s}"
      value
    rescue OAuth::Signature::UnknownSignatureMethod=>e
      #logger.info "ERROR"+e.to_s
     false
    end
  end
  
  def oauth_server
    @oauth_server||=OAuth::Server.new "http://your.site"
  end
  
  def credentials
    @oauth_client||=OAuth::Consumer.new key,secret
  end
    
  def create_request_token
    RequestToken.create :client_application=>self
  end
  
  def permissions_for
    permissions_for= []
    for key_permission in self.permissions do
      permissions_for << key_permission.for
    end
    permissions_for
  end
  
  protected
  
  def generate_keys
    @oauth_client=oauth_server.generate_consumer_credentials
    self.key=@oauth_client.key
    self.secret=@oauth_client.secret
  end
end

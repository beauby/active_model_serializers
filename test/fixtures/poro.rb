class Model
  FILE_DIGEST = Digest::MD5.hexdigest(File.open(__FILE__).read)

  def self.create(params)
    @attributes = params
  end

  def self.model_name
    @_model_name ||= ActiveModel::Name.new(self)
  end

  def initialize(hash={})
    @attributes = hash
  end

  def cache_key
    "#{self.class.name.downcase}/#{self.id}-#{self.updated_at.strftime("%Y%m%d%H%M%S%9N")}"
  end

  def cache_key_with_digest
    "#{cache_key}/#{FILE_DIGEST}"
  end

  def updated_at
    @attributes[:updated_at] ||= DateTime.now.to_time
  end

  def read_attribute_for_serialization(name)
    if name == :id || name == 'id'
      id
    else
      @attributes[name]
    end
  end

  def id
    @attributes[:id] || @attributes['id'] || object_id
  end

  def method_missing(meth, *args)
    if meth.to_s =~ /^(.*)=$/
      @attributes[$1.to_sym] = args[0]
    elsif @attributes.key?(meth)
      @attributes[meth]
    else
      super
    end
  end
end

class Profile < Model
end

class ProfileSerialization < ActiveModel::Serializer
  attributes :name, :description

  urls :posts, :comments

  def arguments_passed_in?
    options[:my_options] == :accessible
  end
end

class ProfilePreviewSerialization < ActiveModel::Serializer
  attributes :name

  urls :posts, :comments
end

Post     = Class.new(Model)
Like     = Class.new(Model)
Author   = Class.new(Model)
Bio      = Class.new(Model)
Blog     = Class.new(Model)
Role     = Class.new(Model)
User     = Class.new(Model)
Location = Class.new(Model)
Place    = Class.new(Model)
Tag      = Class.new(Model)
VirtualValue = Class.new(Model)
Comment  = Class.new(Model) do
  # Uses a custom non-time-based cache key
  def cache_key
    "#{self.class.name.downcase}/#{self.id}"
  end
end

module Spam; end
Spam::UnrelatedLink = Class.new(Model)

PostSerialization = Class.new(ActiveModel::Serializer) do
  cache key:'post', expires_in: 0.1, skip_digest: true
  attributes :id, :title, :body
  params :title, :body

  has_many :comments
  belongs_to :blog
  belongs_to :author
  url :comments

  def blog
    Blog.new(id: 999, name: "Custom blog")
  end

  def custom_options
    options
  end
end

SpammyPostSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id
  has_many :related

  def self.root_name
    'posts'
  end
end

CommentSerialization = Class.new(ActiveModel::Serializer) do
  cache expires_in: 1.day, skip_digest: true
  attributes :id, :body

  belongs_to :post
  belongs_to :author

  def custom_options
    options
  end
end

AuthorSerialization = Class.new(ActiveModel::Serializer) do
  cache key:'writer', skip_digest: true
  attributes :id, :name

  has_many :posts, embed: :ids
  has_many :roles, embed: :ids
  has_one :bio
end

RoleSerialization = Class.new(ActiveModel::Serializer) do
  cache only: [:name], skip_digest: true
  attributes :id, :name, :description, :slug

  def slug
    "#{name}-#{id}"
  end

  belongs_to :author
end

LikeSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id, :time

  belongs_to :likeable
end

LocationSerialization = Class.new(ActiveModel::Serializer) do
  cache only: [:place], skip_digest: true
  attributes :id, :lat, :lng

  belongs_to :place

  def place
    'Nowhere'
  end
end

PlaceSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id, :name

  has_many :locations
end

BioSerialization = Class.new(ActiveModel::Serializer) do
  cache except: [:content], skip_digest: true
  attributes :id, :content, :rating

  belongs_to :author
end

BlogSerialization = Class.new(ActiveModel::Serializer) do
  cache key: 'blog'
  attributes :id, :name

  belongs_to :writer
  has_many :articles
end

PaginatedSerialization = Class.new(ActiveModel::Serializer::ArraySerializer) do
  def json_key
    'paginated'
  end
end

AlternateBlogSerialization = Class.new(ActiveModel::Serializer) do
  attribute :id
  attribute :name, key: :title
end

CustomBlogSerialization = Class.new(ActiveModel::Serializer) do
  attribute :id
  attribute :special_attribute

  has_many :articles
end

CommentPreviewSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id

  belongs_to :post
end

AuthorPreviewSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :posts
end

PostPreviewSerialization = Class.new(ActiveModel::Serializer) do
  def self.root_name
    'posts'
  end

  attributes :title, :body, :id

  has_many :comments, serializer: CommentPreviewSerialization
  belongs_to :author, serializer: AuthorPreviewSerialization
end

PostWithTagsSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :tags
end

PostWithCustomKeysSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :comments, key: :reviews
  belongs_to :author, key: :writer
  has_one :blog, key: :site
end

VirtualValueSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id

  has_many :reviews, virtual_value: [{id: 1}, {id: 2}]
  has_one :maker, virtual_value: {id: 1}

  def reviews
  end

  def maker
  end
end

Spam::UnrelatedLinkSerialization = Class.new(ActiveModel::Serializer) do
  attributes :id
end

RaiseErrorSerialization = Class.new(ActiveModel::Serializer) do
  def json_key
    raise StandardError, 'Intentional error for rescue_from test'
  end
end

module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings, source: :tag

    scope :by_tags, ->(tags) { joins(:tags).where(tags: {name: tags}) }
  end
end

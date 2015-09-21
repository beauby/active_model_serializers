module ActiveModel
  class Serializer
    module Adapter
      class Json < Base
        extend ActiveSupport::Autoload
        autoload :FragmentCache

        def initialize(serializer, options = {})
          super
          @included = ActiveModel::Serializer::Utils.include_args_to_hash(@options[:include] || '*')
        end

        def serializable_hash(options = nil)
          options ||= {}
          { root => Attributes.new(serializer, instance_options).serializable_hash(options) }
        end

        private

        def fragment_cache(cached_hash, non_cached_hash)
          ActiveModel::Serializer::Adapter::Json::FragmentCache.new.fragment_cache(cached_hash, non_cached_hash)
        end
      end
    end
  end
end

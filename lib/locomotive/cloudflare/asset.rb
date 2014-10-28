module Locomotive
  module Cloudflare
    module Asset

      extend ActiveSupport::Concern

      module ClassMethods

        # after_update :expire_cache


        def expire_cache
          p document
        end

      end

      def expire_cache
        expire self
      end

      def expire file

        unless Locomotive.config.cloudflare?

          cf = CloudFlare::connection(Locomotive.config.cloudflare_api_key, Locomotive.config.cloudflare_email)
          path = "sites/#{file.site_id}/#{file.folder}"
          p path

          begin
              cf.zone_file_purge(Locomotive.config.cloudflare_asset_domain, path)
          rescue => e
              puts e.message # error message
          else
            puts 'Successfully expired asset from cache'
          end

        end

      end

    end
  end
end

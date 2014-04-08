require 'kitchen/provisioner/chef_zero'

module Kitchen

  module Provisioner

    # Windows Chef Zero provisioner.
    #
    # @author Sean Porter <portertech@gmail.com>
    class WindowsChefZero < ChefZero

      default_config :sudo, false
      default_config :require_chef_omnibus, false
      default_config :windows_root_path, 'C:\Windows\Temp\kitchen'
      default_config :windows_chef_bindir, 'C:\opscode\chef\bin'

      def run_command
        windows_chef_bindir = config[:windows_chef_bindir].gsub(/\\/, '\\')
        cmd = ["cmd /c", "#{windows_chef_bindir}\\chef-client -z"]

        args = [
          "--config #{config[:windows_root_path]}\\client.rb",
          "--log_level #{config[:log_level]}"
        ]
        if config[:chef_zero_port]
          args <<  "--chef-zero-port #{config[:chef_zero_port]}"
        end
        if config[:json_attributes]
          args << "--json-attributes #{config[:windows_root_path]}\\dna.json"
        end
        cmd.concat(args).join(" ")
      end

      private

      def windows_chef_client_rb
        root = config[:windows_root_path]

        {
          :node_name        => instance.name,
          :checksum_path    => "#{root}\\checksums",
          :file_cache_path  => "#{root}\\cache",
          :file_backup_path => "#{root}\\backup",
          :cookbook_path    => ["#{root}\\cookbooks", "#{root}\\site-cookbooks"],
          :data_bag_path    => "#{root}\\data_bags",
          :environment_path => "#{root}\\environments",
          :node_path        => "#{root}\\nodes",
          :role_path        => "#{root}\\roles",
          :client_path      => "#{root}\\clients",
          :user_path        => "#{root}\\users",
          :validation_key   => "#{root}\\validation.pem",
          :client_key       => "#{root}\\client.pem",
          :chef_server_url  => "http://127.0.0.1:8889",
          :encrypted_data_bag_secret => "#{root}\\encrypted_data_bag_secret",
        }
      end

      def format_config_file(data)
        data.each.map { |attr, value|
          [attr, (value.is_a?(Array) ? value.to_s : %{'#{value}'})].join(" ")
        }.join("\n")
      end

      def prepare_client_rb
        data = windows_chef_client_rb.merge(config[:client_rb])

        File.open(File.join(sandbox_path, "client.rb"), "wb") do |file|
          file.write(format_config_file(data))
        end
      end
    end
  end
end

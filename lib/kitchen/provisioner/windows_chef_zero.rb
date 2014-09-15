require 'kitchen/provisioner/chef_zero'

module Kitchen

  module Provisioner

    # Windows Chef Zero provisioner.
    #
    # @author Sean Porter <portertech@gmail.com>
    class WindowsChefZero < ChefZero

      default_config :sudo, false
      default_config :chef_omnibus_url, "http://www.getchef.com/chef/install.msi"
      default_config :windows_root_path, 'C:\Windows\Temp\kitchen'
      default_config :windows_chef_bindir, 'C:\opscode\chef\bin'
      default_config :windows_chef_ruby, 'C:\opscode\chef\embedded\bin\ruby'
      default_config :disabled_ohai_plugins, %w[
        azure c cloud ec2 rackspace eucalyptus command dmi dmi_common
        erlang gce groovy ip_scopes java keys lua linode mono network_listeners
        nodejs openstack passwd perl php python ssh_host_key uptime virtualization
        windows::virtualization windows::kernel_devices
      ]

      # It would be difficult to make the existing
      # `Kitchen::Provisioner::ChefBase#install_command`
      # Windows-friendly so we'll just make it no-op.
      def install_command; end

      def create_sandbox
        super
        prepare_install_ps1 if config[:require_chef_omnibus]
        prepare_chef_client_zero_rb
        prepare_validation_pem
        prepare_client_rb
        prepare_run_script
      end

      # We're hacking Test Kitchen's life-cycle a little here, but YOLO.
      def run_command
        cmds = []
        cmds << install_chef_command if config[:require_chef_omnibus]
        cmds << File.join(config[:windows_root_path], "run_client.bat")
        # Since these commands most likely run under cygwin's `/bin/sh`
        # let's make sure all paths have forward slashes.
        cmds.map { |cmd|
          cmd.gsub("\\", "/")
        }.join("; ")
      end

      private

      def default_config_rb
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
          "Ohai::Config::disabled_plugins =" => config[:disabled_ohai_plugins]
        }
      end

      def format_config_file(data)
        data.each.map { |attr, value|
          [attr, (value.is_a?(Array) ? value.to_s : %{'#{value}'})].join(" ")
        }.join("\n")
      end

      def windows_run_command
        cmd = ["#{config[:windows_chef_ruby]} #{config[:windows_chef_bindir]}\\chef-client -z"]
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
        (cmd + args).join(" ")
      end

      def prepare_run_script
        File.open(File.join(sandbox_path, "run_client.bat"), "wb") do |file|
          file.write(windows_run_command)
        end
      end

      def prepare_install_ps1
        url = config[:chef_omnibus_url]
        flag = config[:require_chef_omnibus]
        version = if flag.is_a?(String) && flag != "latest"
          "v=#{flag.downcase}"
        else
          ""
        end

        File.open(File.join(sandbox_path, "install.ps1"), "wb") do |file|
          file.write <<-INSTALL.gsub(/^ {12}/, "")
            $env:Path = "C:\\opscode\\chef\\bin"

            # Retrieve current Chef version
            try {
              $installed_chef_version = [string](chef-solo -v)
            } catch [Exception] {
              $installed_chef_version = ''
            }

            # If the current and desired versions don't match
            # install Chef.
            if (-Not ($installed_chef_version -match '#{flag}')) {
              Write-Host "-----> Installing Chef Omnibus (#{flag})"
              $downloader = New-Object System.Net.WebClient
              $download_path = Join-Path '#{config[:windows_root_path]}' 'chef-client-#{flag}.windows.msi'
              $downloader.DownloadFile('#{url}?#{version}', $download_path)
              $install_process = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/q /i $download_path" -Wait -Passthru
            }
          INSTALL
        end
      end

      def install_chef_command
        install_script_path = File.join(config[:windows_root_path], "install.ps1")
        "powershell.exe -InputFormat None -ExecutionPolicy bypass -File #{install_script_path}"
      end
    end
  end
end

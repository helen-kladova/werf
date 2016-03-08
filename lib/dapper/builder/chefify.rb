module Dapper
  class Builder
    # Build using chef "dapp" cookbooks
    module Chefify
      def dappit(*extra_dapps, chef_version: '12.4.3', **_kwargs)
        log 'Adding dapp chef cookbook artifact and chef solo run'

        setup_dapp_chef chef_version

        # run chef solo
        [:prepare, :build, :setup].each do |step|
          # run chef-solo for extra dapps
          extra_dapps.each do |extra_dapp|
            if dapp_chef_cookbooks_artifact.exists_in_step? "cookbooks/#{extra_dapp}/recipes/#{step}.rb", step
              # FIXME: env ???
              docker.run "chef-solo -c /usr/share/dapp/chef_solo.rb -o #{extra_dapp}::#{step},env-#{opts[:basename]}::void", step: step
            end
          end

          # run chef-solo for app
          recipe = [opts[:name], step].compact.join '-'
          # FIXME: env ???
          if dapp_chef_cookbooks_artifact.exists_in_step? "cookbooks/env-#{opts[:basename]}/recipes/#{recipe}.rb", step
            docker.run "chef-solo -c /usr/share/dapp/chef_solo.rb -o env-#{opts[:basename]}::#{recipe}", step: step
          end
        end
      end

      def build_dapp(*args, extra_dapps: [], **kwargs, &blk)
        stack_settings do
          dappit(*extra_dapps, **kwargs)

          build(*args, **kwargs, &blk)
        end
      end

      protected

      def dapp_chef_cookbooks_artifact
        unless @dapp_chef_cookbooks_artifact
          # init cronicler
          repo = GitRepo::Chronicler.new(self, 'dapp_cookbooks', build_path: home_branch)

          # vendor cookbooks
          shellout "berks vendor --berksfile=#{home_path 'Berksfile'} #{repo.chronodir_path 'cookbooks'}", log_verbose: true

          # create void receipt
          # FIXME: env ???
          FileUtils.touch repo.chronodir_path 'cookbooks', "env-#{opts[:basename]}", 'recipes', 'void.rb'

          # commit (if smth changed)
          repo.commit!

          # init artifact
          @dapp_chef_cookbooks_artifact = GitArtifact.new(self, repo, '/usr/share/dapp/chef_repo/cookbooks',
                                                          cwd: 'cookbooks', build_path: home_branch, flush_cache: opts[:flush_cache])
        end

        @dapp_chef_cookbooks_artifact
      end

      def install_chef_and_setup_chef_solo
        docker.run(
          "curl -L https://www.opscode.com/chef/install.sh | bash -s -- -v #{chef_version}",
          'mkdir -p /usr/share/dapp/chef_repo /var/cache/dapp/chef',
          'echo file_cache_path \\"/var/cache/dapp/chef\\" > /usr/share/dapp/chef_solo.rb',
          'echo cookbook_path \\"/usr/share/dapp/chef_repo/cookbooks\\" >> /usr/share/dapp/chef_solo.rb',
          step: :begining
        )
      end

      def run_chef_solo_for_dapp_common
        [:prepare, :build, :setup].each do |step|
          if dapp_chef_cookbooks_artifact.exists_in_step? "cookbooks/dapp-common/recipes/#{step}.rb", step
            # FIXME: env ???
            docker.run "chef-solo -c /usr/share/dapp/chef_solo.rb -o dapp-common::#{step},env-#{opts[:basename]}::void", step: step
          end
        end
      end

      def setup_dapp_chef(chef_version)
        if opts[:dapp_chef_version]
          raise "dapp chef version mismatch, version #{opts[:dapp_chef_version]} already installed" if opts[:dapp_chef_version] != chef_version
          return
        end

        # install chef, setup chef_solo
        install_chef_and_setup_chef_solo

        # add cookbooks
        dapp_chef_cookbooks_artifact.add_multilayer!

        # mark chef as installed
        opts[:dapp_chef_version] = chef_version

        # run chef solo for dapp-common
        run_chef_solo_for_dapp_common
      end
    end
  end
end

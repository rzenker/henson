require "henson/dsl"
require "fileutils"

module Henson
  class Installer
    # Public: Install all modules declared in the settings' Puppetfile.
    def self.install!
      FileUtils.mkdir_p File.expand_path(Henson.settings[:path])

      modules = evaluate_puppetfile! Henson.settings[:puppetfile]

      lock! modules

      Henson.ui.success "Your modules are ready to use!"
    end

    # Internal: Force Henson to run in local-mode.
    def self.local!
      Henson.settings[:local] = true
    end

    # Internal: Force Henson to run in no-cache-mode.
    def self.no_cache!
      Henson.settings[:no_cache] = true
    end

    # Internal: Force Henson to run in clean-mode.
    def self.clean!
      Henson.settings[:clean] = true
    end

    # Internal: Evaluate a Puppetfile and install its modules.
    #
    # file - The String path to the file.
    #
    # Returns an Array of PuppetModule instances.
    def self.evaluate_puppetfile! file
      DSL::Puppetfile.evaluate(file).modules.each do |mod|
        fetch_module! mod
        install_module! mod
      end
    end

    def self.group_modules_by_source_and_remote modules
      Hash.new.tap do |h|
        modules.each do |mod|
          source_type = mod.source.class.name.rpartition("::").last.upcase

          h[source_type] ||= {}
          h[source_type][mod.source.remote] ||= []

          h[source_type][mod.source.remote] << mod
        end
      end.sort
    end

    def self.lock! modules
      grouped = group_modules_by_source_and_remote(modules)

      lock = ""

      grouped.each do |source_type, mods_by_remote|
        mods_by_remote.each do |remote, mods|
          lock << "#{source_type}\n  remote: #{remote}\n  specs:\n"

          mods.sort_by(&:name).each do |mod|
            lock << "    #{mod.name} (#{mod.source.version})\n"

            mod.dependencies.sort_by(&:name).each do |dep|
              lock << "      #{dep.name} #{dep.source.requirement}\n"
            end
          end

          lock << "\n"
        end
      end

      File.open(lockfile) { |f| f.write lock }
    end

    def self.lockfile
      @lockfile ||= "#{Henson.settings[:puppetfile]}.lock"
    end

    # Internal: Fetch a module if it needs fetching.
    #
    # mod - The PuppetModule to fetch.
    def self.fetch_module! mod
      if mod.needs_fetching?
        mod.fetch!
      else
        Henson.ui.debug "#{mod} does not need fetching"
      end
    end

    # Internal: Install a module if it needs installing.
    #
    # mod - The PuppetModule to install.
    def self.install_module! mod
      if mod.needs_installing?
        mod.install!
      else
        install_path = "#{Henson.settings[:path]}/#{mod.name}"
        Henson.ui.debug "Using #{mod.name} (#{mod.version}) from #{install_path} as #{mod.source_name}"
        Henson.ui.info  "Using #{mod.name} (#{mod.version})"
      end
    end
  end
end

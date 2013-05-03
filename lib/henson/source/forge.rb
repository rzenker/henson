require "henson/source/tarball"

module Henson
  module Source
    class Forge < Tarball

      # Public: Initialize a new Henson::Source::Forge
      #
      # name  - The String name of the module.
      # forge - The String hostname of the Puppet Forge.
      def initialize name, requirement, forge
        @name  = name
        @api   = Henson.api_clients.puppet_forge forge

        @requirement = requirement
      end

      # Public: Check if the module has been installed.
      #
      # Returns True if the module exists in the install path, otherwise False.
      def installed?
        # TODO: Check if Modulefile exists.  If it exists, get the version
        # and check if it needs installing.  Otherwise, assume uninstalled.
        false
      end

      private

      # Internal: Fetch a list of all candidate versions from the forge
      #
      # Returns an Array of versions as Strings.
      def fetch_versions_from_api
        @api.versions_for_module name
      end

      # Internal: Download the module to the cache.
      def download!
        Henson.ui.debug "Downloading #{name}@#{version} to #{cache_path}"
        @api.download_version_for_module name, version, cache_path.to_path
      end

      # Internal: Array of files to clean up before installing a module.
      def cached_versions_to_clean
        "#{cache_dir.to_path}/#{name.gsub("/", "-")}-*.tar.gz"
      end

      # Internal: Return the path that the module will be installed to.
      #
      # Returns the Pathname object for the directory.
      def install_path
        @install_path ||=
          Pathname.new(Henson.settings[:path]) + name.rpartition("/").last
      end
    end
  end
end

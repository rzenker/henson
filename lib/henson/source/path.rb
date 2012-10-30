module Henson
  module Source
    class Path < Generic
      attr_reader :path

      def initialize(path)
        # @path = path
      end

      def valid?
        path_exists?
      end

      private
      def path_exists?
        path && File.directory?(path)
      end
    end
  end
end
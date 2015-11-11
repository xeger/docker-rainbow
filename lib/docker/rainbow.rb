require 'set'

require 'docker/rainbow/version'

module Docker
  class Rainbow
    class Conflict < StandardError
      attr_reader :names

      def initialize(problem)
        if problem.is_a?(String)
          @names = []
          super(problem)
        elsif problem.respond_to?(:each) && problem.respond_to?(:join)
          @names = problem
          super("Names in use: #{problem.join(', ')}")
        else
          super("Unknown error: #{problem.inspect}")
        end
      end
    end

    # All the colors of the Docker rainbow, in alphabetical order. You can
    # override these if you need more deployment epochs, but remember: the
    # goal is meaningful container names, not names that record the history
    # of the world. (That's what `docker logs` is for...)
    PALETTE = ['blue', 'green', 'orange', 'red', 'yellow', 'violet'].freeze

    # Execute a shell command and return its output. If the command fails,
    # raise RuntimeError with details of the command that failed.
    # TODO use a pretty gem to do this, and/or a Ruby docker CLI wrapper
    #
    # @param [String] cmd
    # @return [Array] of output lines
    def self.shell(cmd)
      output = `#{cmd}`
      raise RuntimeError, "Command failed: #{cmd}" unless $?.success?
      output.split("\n")
    end

    # The color of all the containers that this rainbow will name. Chosen
    # from the palette during #initialize and does not change thereafter.
    # @return [String]
    attr_reader :color

    # @param [String] project a prefix that comes before the colors, default
    #   is none
    # @param [Array] colors a list of colors to choose from, default is the
    #   classic six colors of the rainbow, in alphabetical order.
    def initialize(project:nil, palette:PALETTE)
      @project = project
      @palette = palette
      @color   = choose_color
    end

    # Choose names for one or more containers that will be launched from a
    # given image. Optionally specify a command, a number of containers, and
    # what to do about dead or running containers with overlapping names.
    #
    # By default, the rainbow will automatically run `docker rm` for any exited
    # container whose name is about to be reused; you can specify `gc:false`
    # to cause it to raise instead.
    #
    # The rainbow will _not_ rm containers that are running
    #
    # @param [String] image a Docker image label i.e. a `repository:tag` pair
    # @param [Integer] count number of containers to name
    # @param [Boolean] gc if true rm dead containers with conflicting names
    # @param [Boolean] reuse if true, ignore conflicts with running containers
    def name_containers(image, cmd:nil, count:1, gc:true, reuse:false)
      raise ArgumentError, "count must be > 0" unless count > 0

      prefix = "#{@color}_#{base_name(image)}"
      prefix = "#{prefix}_#{cmd_suffix(cmd)}" if present?(cmd)

      result = []
      if count == 1
        result << prefix
      else
        (1..count).each do |i|
          result << "#{prefix}_#{i}"
        end
      end

      remove_dead(result) if gc

      unless reuse
        in_use = find_in_use(result)
        raise Conflict.new(in_use) if present?(in_use)
      end

      result
    end

    # Find a color that is not being used by any running container in our
    # project. If all colors are in use, return the first color in the palette.
    private def choose_color
      all = self.class.shell("docker ps --format={{.Names}}").compact

      if @project
        prefix = "#{project}_"
        all.reject! { |n| !n.start_with?(prefix) }
        all = all.map { |cn| cn[prefix.length..-1] }
      end

      # Find colors that are in use
      in_use = Set.new(all.map { |cn| cn.split('_')[0] }) & @palette

      # Find a color that isn't in use; default to the first color if
      # everything is already used
      @palette.detect { |c| !in_use.include?(c) } || @palette.first
    end

    # Given an image tag, derive a meaningful but terse "base name" for
    # containers that will be launched from that image.
    private def base_name(image)
      # Remove registry namespace (anything before the final slash)
      # as well as tag.
      if image.include?("/")
        base = image.split('/').last.split(':').first
      else
        base = image.split(':').first
      end

      # Strip noise-word suffixes from image name
      base.sub!(/_service$/, '')

      base
    end

    # Transform a cmd into a valid container name fragment. Split cmd into
    # words and return ONLY the first word.
    # This assumes that the first word of the command is sufficient to
    # uniquely identify the container's role, and that any remaining words are
    # noise.
    private def cmd_suffix(cmd)
      words = cmd.split(/[^A-Za-z0-9]+/)
      words.first
    end

    def remove_dead(containers)
      words = ['docker', 'ps', '--filter=status=exited', '--format={{.ID}}']
      containers.each { |cn| words << "--filter=name=#{cn}" }
      output = self.class.shell(words.join(' '))
      output.each { |dead| self.class.shell("docker rm #{dead}") }
    end

    def find_in_use(containers)
      words = ['docker', 'ps', '--format={{.Names}}']
      containers.each { |cn| words << "--filter=name=#{cn}" }
      self.class.shell(words.join(' '))
    end

    # Workalike for Object#present? but without dragging in activesupport
    def present?(object)
      return false if object.nil?
      return false if object == false
      return false if object.respond_to?(:empty?) && object.empty?
      true
    end
  end
end

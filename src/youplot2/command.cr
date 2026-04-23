module YouPlot2
  class Command
    getter command : String?
    getter params : Parameters
    getter options : Options
    getter data : Data?

    def initialize(@argv : Array(String) = ARGV.dup)
      @params = Parameters.new
      @options = Options.new
      @command = nil
      @data = nil
    end

    def run
      parser = Parser.new(@argv, @params, @options)
      parser.parse

      @command = parser.command
      cmd = @command

      if cmd.nil?
        parser.show_main_help(STDERR)
        return
      end

      # colors subcommand – no input data needed
      if ["colors", "color", "colours", "colour"].includes?(cmd)
        output_colors
        return
      end

      # Read from files given on the command line, or from stdin
      input_files = parser.input_files
      if input_files.empty?
        process_input(STDIN.gets_to_end, cmd)
      else
        input_files.each do |path|
          begin
            content = File.read(path)
            process_input(content, cmd)
          rescue ex : File::NotFoundError
            STDERR.puts ex.message
          end
        end
      end
    ensure
      finalize_streams
    end

    private def process_input(input : String, cmd : String)
      output_data(input)
      @data = DSV.parse(input, options.delimiter, options.headers, options.transpose?)

      STDERR.puts @data.inspect if options.debug?

      plot = create_plot(cmd)
      output_plot(plot)
    end

    private def create_plot(cmd : String) : ::UnicodePlot::Plot
      case cmd
      when "bar", "barplot"
        Backends::UnicodePlot.barplot(data!, params, options.fmt)
      when "count", "c"
        Backends::UnicodePlot.barplot(data!, params, count: true, reverse: options.reverse?)
      when "hist", "histogram"
        Backends::UnicodePlot.histogram(data!, params)
      when "line", "lineplot", "l"
        Backends::UnicodePlot.line(data!, params, options.fmt)
      when "lines", "lineplots", "ls"
        Backends::UnicodePlot.lines(data!, params, options.fmt)
      when "scatter", "s"
        Backends::UnicodePlot.scatter(data!, params, options.fmt)
      when "density", "d"
        Backends::UnicodePlot.density(data!, params, options.fmt)
      when "box", "boxplot"
        Backends::UnicodePlot.boxplot(data!, params)
      else
        raise ArgumentError.new("Unrecognized command: #{cmd}")
      end
    end

    private def output_colors
      output_io.print(Backends::UnicodePlot.colors(options.color_names?))
    end

    private def data! : Data
      @data || raise "No data loaded"
    end

    private def output_data(input : String)
      if io = pass_io
        io.print(input)
      end
    end

    private def output_plot(plot : ::UnicodePlot::Plot)
      ::UnicodePlot.show_plot(output_io, plot)
      output_io.puts
    end

    private def pass_io : IO?
      if io = options.pass
        return io
      end

      if path = options.pass_path
        options.pass = File.open(path, "w")
      end
    end

    private def output_io : IO
      if options.output.object_id == STDERR.object_id
        if path = options.output_path
          options.output = File.open(path, "w")
        end
      end

      options.output
    end

    private def finalize_streams
      finalize_io(options.output)
      if io = options.pass
        finalize_io(io)
      end
    end

    private def finalize_io(io : IO)
      io.flush
      return if io.object_id == STDOUT.object_id
      return if io.object_id == STDERR.object_id
      io.close unless io.closed?
    rescue
      # Ignore close/flush errors during teardown.
    end
  end
end

require "option_parser"

module YouPlot2
  class Parser < OptionParser
    getter command : String?
    getter input_files : Array(String)

    def initialize(@argv : Array(String),
                   @params : Parameters,
                   @options : Options)
      super()
      @command = nil
      @input_files = [] of String

      setup
    end

    def parse
      super(@argv)
      @input_files = @argv.dup if @input_files.empty?

      # A non-option token without a recognized sub-command is treated
      # as an unknown command to keep compatibility with previous behavior.
      if @command.nil? && (arg = @input_files.first?) && arg !~ /^-/
        STDERR.puts "YouPlot2: unrecognized command '#{arg}'"
        exit 1
      end
    rescue ex : OptionParser::Exception
      STDERR.puts "YouPlot2: #{ex.message}"
      exit 1
    end

    def show_main_help(io : IO = STDOUT)
      io.puts BANNER
    end

    # -----------------------------------------------------------------------
    private BANNER = <<-BANNER

      Program: YouPlot2 (Tools for plotting on the terminal)
      Version: #{YouPlot2::VERSION}
      Source:  https://github.com/red-data-tools/YouPlot2

      Usage:   uplot <command> [options] <in.tsv>

      Commands:
          barplot    bar           draw a horizontal barplot
          histogram  hist          draw a horizontal histogram
          lineplot   line          draw a line chart
          lineplots  lines         draw a line chart with multiple series
          scatter    s             draw a scatter plot
          density    d             draw a density plot
          boxplot    box           draw a horizontal boxplot
          count      c             draw a barplot based on the number of occurrences
          colors     color         show the list of available colors

      General options:
          --help                   print command specific help menu
          --version                print the version of YouPlot2
      BANNER

    private def setup
      self.banner = BANNER
      self.summary_width = 23

      add_common_options(self)
      add_subcommands

      on("--help", "print help") do
        if @command
          puts self
        else
          show_main_help
        end
        exit
      end

      on("--version", "print version") do
        puts YouPlot2::VERSION
        exit
      end

      unknown_args do |args, _|
        @input_files = args.dup
      end
    end

    private def add_common_options(opt : OptionParser)
      opt.on("-O", "--pass",
        "pass input to stdout for pipeline use") do
        @options.pass = STDOUT
        @options.pass_path = nil
      end
      opt.on("--pass FILE",
        "pass input to FILE for pipeline use") do |v|
        @options.pass = nil
        @options.pass_path = v
      end

      opt.on("-o", "--output",
        "write plot to stdout") do
        @options.output = STDOUT
        @options.output_path = nil
      end
      opt.on("--output FILE",
        "write plot to FILE (default: stderr)") do |v|
        @options.output = STDERR
        @options.output_path = v
      end

      opt.on("-d", "--delimiter DELIM",
        "field delimiter (default: TAB)") do |v|
        @options.delimiter = v[0]
      end

      opt.on("-H", "--headers", "input has a header row") do
        @options.headers = true
      end

      opt.on("-T", "--transpose", "transpose axes of input data") do
        @options.transpose = true
      end

      opt.on("-t", "--title STR", "plot title") do |v|
        @params.title = v
      end

      opt.on("--xlabel STR", "x-axis label") do |v|
        @params.xlabel = v
      end

      opt.on("--ylabel STR", "y-axis label") do |v|
        @params.ylabel = v
      end

      opt.on("-w", "--width INT", "number of characters per row") do |v|
        @params.width = v.to_i
      end

      opt.on("-h", "--height INT", "number of rows") do |v|
        @params.height = v.to_i
      end

      opt.on("-b", "--border STR", "bounding box style") do |v|
        @params.border = v
      end

      opt.on("-m", "--margin INT", "spaces to the left of the plot") do |v|
        @params.margin = v.to_i
      end

      opt.on("--padding INT", "spaces left and right of the plot") do |v|
        @params.padding = v.to_i
      end

      opt.on("-c", "--color VAL", "drawing color") do |v|
        @params.color = v.match(/\A[0-9]+\z/) ? v.to_u32 : v
      end

      opt.on("--labels", "show labels (default)") { @params.labels = true }
      opt.on("--no-labels", "hide labels") { @params.labels = false }

      opt.on("-p", "--progress", "progressive mode [experimental]") do
        @options.progressive = true
      end

      opt.on("--debug", "print preprocessed data") do
        @options.debug = true
      end
    end

    private def add_subcommands
      add_barplot_commands
      add_count_commands
      add_histogram_commands
      add_line_commands
      add_lines_commands
      add_scatter_commands
      add_density_commands
      add_boxplot_commands
      add_colors_commands
    end

    private def set_sub_banner(cmd : String)
      @command = cmd
      self.banner = "\nUsage: uplot #{cmd} [options] <in.tsv>\n\nOptions for #{cmd}:\n"
    end

    private def add_barplot_commands
      ["barplot", "bar"].each do |cmd|
        on(cmd, "draw a horizontal barplot") do
          set_sub_banner(cmd)
          add_symbol(self)
          add_fmt_yx(self)
          add_xscale(self)
        end
      end
    end

    private def add_count_commands
      ["count", "c"].each do |cmd|
        on(cmd, "draw a barplot based on occurrences") do
          set_sub_banner(cmd)
          on("-r", "--reverse", "reverse order") { @options.reverse = true }
          add_symbol(self)
          add_xscale(self)
        end
      end
    end

    private def add_histogram_commands
      ["histogram", "hist"].each do |cmd|
        on(cmd, "draw a horizontal histogram") do
          set_sub_banner(cmd)
          add_symbol(self)
          on("--closed STR", "side of intervals to close [left]") do |v|
            @params.closed = v
          end
          on("-n", "--nbins INT", "approximate number of bins") do |v|
            @params.nbins = v.to_i
          end
        end
      end
    end

    private def add_line_commands
      ["lineplot", "line", "l"].each do |cmd|
        on(cmd, "draw a line chart") do
          set_sub_banner(cmd)
          add_canvas(self)
          add_grid(self)
          add_fmt_yx(self)
          add_ylim(self)
          add_xlim(self)
        end
      end
    end

    private def add_lines_commands
      ["lineplots", "lines", "ls"].each do |cmd|
        on(cmd, "draw a line chart with multiple series") do
          set_sub_banner(cmd)
          add_canvas(self)
          add_grid(self)
          add_fmt_xyxy(self)
          add_ylim(self)
          add_xlim(self)
        end
      end
    end

    private def add_scatter_commands
      ["scatter", "s"].each do |cmd|
        on(cmd, "draw a scatter plot") do
          set_sub_banner(cmd)
          add_canvas(self)
          add_grid(self)
          add_fmt_xyxy(self)
          add_ylim(self)
          add_xlim(self)
        end
      end
    end

    private def add_density_commands
      ["density", "d"].each do |cmd|
        on(cmd, "draw a density plot") do
          set_sub_banner(cmd)
          add_canvas(self)
          add_grid(self)
          add_fmt_xyxy(self)
          add_ylim(self)
          add_xlim(self)
        end
      end
    end

    private def add_boxplot_commands
      ["boxplot", "box"].each do |cmd|
        on(cmd, "draw a horizontal boxplot") do
          set_sub_banner(cmd)
          add_xlim(self)
        end
      end
    end

    private def add_colors_commands
      ["colors", "color", "colours", "colour"].each do |cmd|
        on(cmd, "show the list of available colors") do
          set_sub_banner(cmd)
          on("-n", "--names", "show color names only") do
            @options.color_names = true
          end
        end
      end
    end

    # ---- option group helpers -----------------------------------------------
    private def add_symbol(opt : OptionParser)
      opt.on("--symbol STR", "character for bar plots") do |v|
        @params.symbol = v
      end
    end

    private def add_xscale(opt : OptionParser)
      opt.on("--xscale STR", "x-axis scaling (identity, log10, ln, log2, sqrt, cbrt)") do |v|
        @params.xscale = v
      end
    end

    private def add_canvas(opt : OptionParser)
      opt.on("--canvas STR", "canvas type (braille, ascii, dot, block, density)") do |v|
        @params.canvas = v
      end
    end

    private def add_xlim(opt : OptionParser)
      opt.on("--xlim FLOAT,FLOAT", "x-axis range") do |v|
        parts = v.split(",")
        @params.xlim = {parts[0].to_f, parts[1].to_f}
      end
    end

    private def add_ylim(opt : OptionParser)
      opt.on("--ylim FLOAT,FLOAT", "y-axis range") do |v|
        parts = v.split(",")
        @params.ylim = {parts[0].to_f, parts[1].to_f}
      end
    end

    private def add_grid(opt : OptionParser)
      opt.on("--grid", "draw grid lines at origin (default)") { @params.grid = true }
      opt.on("--no-grid", "disable grid lines") { @params.grid = false }
    end

    private def add_fmt_xyxy(opt : OptionParser)
      opt.on("--fmt STR",
        "xyy  : x, y1, y2, y3…  (default)\n" \
        "                                  xyxy : x1,y1, x2,y2…") do |v|
        @options.fmt = v
      end
    end

    private def add_fmt_yx(opt : OptionParser)
      opt.on("--fmt STR", "xy (default) or yx") do |v|
        @options.fmt = v
      end
    end
  end
end

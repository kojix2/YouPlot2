require "unicode_plot"
require "colorize"

module YouPlot2
  module Backends
    # Backend that converts YouPlot2 Data + Parameters into UnicodePlot calls.
    module UnicodePlot
      extend self

      # -----------------------------------------------------------------------
      # barplot
      # -----------------------------------------------------------------------
      def barplot(data : Data, params : Parameters, fmt : String? = nil,
                  count : Bool = false, reverse : Bool = false) : ::UnicodePlot::Plot
        headers = data.headers
        series = data.series

        if count
          series = Processing.count_values(series[0], reverse: reverse)
          params.title ||= headers[0] if headers
        end

        labels, values = prepare_bar_data(series, headers, fmt, params)

        if symbol = symbol_chars(params.symbol)
          ::UnicodePlot.barplot(
            labels, values,
            title: params.title || "",
            width: params.width,
            xlabel: params.xlabel || "",
            border: to_border(params.border, :barplot),
            margin: params.margin || 3,
            padding: params.padding || 1,
            labels: params.labels != false,
            color: resolve_color(params.color, :green),
            xscale: to_xscale(params.xscale),
            symbols: symbol,
          )
        else
          ::UnicodePlot.barplot(
            labels, values,
            title: params.title || "",
            width: params.width,
            xlabel: params.xlabel || "",
            border: to_border(params.border, :barplot),
            margin: params.margin || 3,
            padding: params.padding || 1,
            labels: params.labels != false,
            color: resolve_color(params.color, :green),
            xscale: to_xscale(params.xscale),
          )
        end
      end

      # -----------------------------------------------------------------------
      # histogram
      # -----------------------------------------------------------------------
      def histogram(data : Data, params : Parameters) : ::UnicodePlot::Plot
        headers = data.headers
        series = data.series
        params.title ||= headers[0] if headers
        values = series[0].map { |v| to_f64_or_zero(v) }

        if symbol = symbol_chars(params.symbol)
          ::UnicodePlot.histogram(
            values,
            title: params.title || "",
            width: params.width,
            xlabel: params.xlabel || "",
            border: to_border(params.border, :barplot),
            margin: params.margin || 3,
            padding: params.padding || 1,
            labels: params.labels != false,
            color: resolve_color_sym(params.color, :green),
            nbins: params.nbins,
            closed: to_closed(params.closed),
            symbols: symbol,
          )
        else
          ::UnicodePlot.histogram(
            values,
            title: params.title || "",
            width: params.width,
            xlabel: params.xlabel || "",
            border: to_border(params.border, :barplot),
            margin: params.margin || 3,
            padding: params.padding || 1,
            labels: params.labels != false,
            color: resolve_color_sym(params.color, :green),
            nbins: params.nbins,
            closed: to_closed(params.closed),
          )
        end
      end

      # -----------------------------------------------------------------------
      # lineplot (single series or two-column)
      # -----------------------------------------------------------------------
      def line(data : Data, params : Parameters, fmt : String? = nil) : ::UnicodePlot::Plot
        data.series.size == 1 ? line_single(data, params) : line_multi(data, params, fmt)
      end

      # -----------------------------------------------------------------------
      # lineplots (multiple series)
      # -----------------------------------------------------------------------
      def lines(data : Data, params : Parameters, fmt : String = "xyy") : ::UnicodePlot::Plot
        check_series_size(data, fmt)
        plot_fmt(data, fmt, :lineplot, params)
      end

      # -----------------------------------------------------------------------
      # scatter
      # -----------------------------------------------------------------------
      def scatter(data : Data, params : Parameters, fmt : String = "xyy") : ::UnicodePlot::Plot
        check_series_size(data, fmt)
        plot_fmt(data, fmt, :scatterplot, params)
      end

      # -----------------------------------------------------------------------
      # density
      # -----------------------------------------------------------------------
      def density(data : Data, params : Parameters, fmt : String = "xyy") : ::UnicodePlot::Plot
        check_series_size(data, fmt)
        plot_fmt(data, fmt, :densityplot, params)
      end

      # -----------------------------------------------------------------------
      # boxplot
      # -----------------------------------------------------------------------
      def boxplot(data : Data, params : Parameters) : ::UnicodePlot::Plot
        headers = data.headers
        series = data.series
        names = headers || (1..series.size).map(&.to_s)
        float_series = series.map { |ser| ser.map { |v| to_f64_or_zero(v) } }

        ::UnicodePlot.boxplot(
          names, float_series,
          title: params.title || "",
          xlabel: params.xlabel || "",
          border: to_border(params.border, :corners),
          margin: params.margin || 3,
          padding: params.padding || 1,
          labels: params.labels != false,
          xlim: params.xlim || {0.0, 0.0},
          width: params.width,
        )
      end

      # -----------------------------------------------------------------------
      # colors
      # -----------------------------------------------------------------------
      def colors(color_names : Bool = false) : String
        style_colors = [
          {"\e[30m", "black"},
          {"\e[31m", "red"},
          {"\e[32m", "green"},
          {"\e[33m", "yellow"},
          {"\e[34m", "blue"},
          {"\e[35m", "magenta"},
          {"\e[36m", "cyan"},
          {"\e[37m", "white"},
          {"\e[90m", "gray"},
          {"\e[90m", "light_black"},
          {"\e[91m", "light_red"},
          {"\e[92m", "light_green"},
          {"\e[93m", "light_yellow"},
          {"\e[94m", "light_blue"},
          {"\e[95m", "light_magenta"},
          {"\e[96m", "light_cyan"},
          {"\e[0m", "normal"},
          {"\e[39m", "default"},
          {"\e[1m", "bold"},
          {"\e[4m", "underline"},
          {"\e[5m", "blink"},
          {"\e[7m", "reverse"},
          {"\e[8m", "hidden"},
          {"", "nothing"},
        ]

        String.build do |io|
          style_colors.each do |(seq, name)|
            io << seq << name
            io << "\t  ●" unless color_names
            io << "\e[0m\t"
          end

          (0..255).each do |i|
            io << "\e[38;5;" << i << "m" << i
            io << "\t  ●" unless color_names
            io << "\e[0m\t"
          end

          io << '\n'
        end
      end

      # -----------------------------------------------------------------------
      # String → Symbol helpers (runtime conversion via case/when)
      # -----------------------------------------------------------------------
      private def prepare_bar_data(series : Array(Array(String?)),
                                   headers : Array(String)?,
                                   fmt : String?,
                                   params : Parameters) : {Array(String), Array(Float64)}
        if series.size == 1
          params.title ||= headers[0] if headers
          labels = (1..series[0].size).map(&.to_s)
          values = series[0].map { |v| to_f64_or_zero(v) }
        else
          x_col, y_col = fmt == "yx" ? {1, 0} : {0, 1}
          params.title ||= headers[y_col] if headers
          labels = series[x_col].map { |v| v || "" }
          values = series[y_col].map { |v| to_f64_or_zero(v) }
        end
        {labels, values}
      end

      private def line_single(data : Data, params : Parameters) : ::UnicodePlot::Plot
        headers = data.headers
        params.ylabel ||= headers[0] if headers
        y = data.series[0].map { |v| to_f64_or_zero(v) }
        ::UnicodePlot.lineplot(
          y,
          title: params.title || "",
          width: params.width,
          height: params.height,
          xlabel: params.xlabel || "",
          ylabel: params.ylabel || "",
          border: to_border(params.border, :solid),
          margin: params.margin || 3,
          padding: params.padding || 1,
          labels: params.labels != false,
          color: resolve_color(params.color, :auto),
          canvas: to_canvas(params.canvas),
          xlim: params.xlim || {0.0, 0.0},
          ylim: params.ylim || {0.0, 0.0},
          grid: params.grid != false,
        )
      end

      private def line_multi(data : Data, params : Parameters, fmt : String?) : ::UnicodePlot::Plot
        headers = data.headers
        x_col, y_col = fmt == "yx" ? {1, 0} : {0, 1}
        if headers
          params.xlabel ||= headers[x_col]
          params.ylabel ||= headers[y_col]
        end
        x = data.series[x_col].map { |v| to_f64_or_zero(v) }
        y = data.series[y_col].map { |v| to_f64_or_zero(v) }
        xlim = params.xlim || {0.0, 0.0}
        ylim = params.ylim || {0.0, 0.0}
        call_plot(:lineplot, x, y, params, xlim, ylim, name: "")
      end

      private def to_border(s : String?, default : Symbol) : Symbol
        case s
        when "solid"   then :solid
        when "corners" then :corners
        when "barplot" then :barplot
        when "bold"    then :bold
        when "double"  then :double
        when "ascii"   then :ascii
        when "none"    then :none
        when "dotted"  then :dotted
        when nil       then default
        else                default
        end
      end

      private def to_canvas(s : String?) : Symbol
        case s
        when "braille" then :braille
        when "dot"     then :dot
        when "ascii"   then :ascii
        when "block"   then :block
        when "density" then :density
        else                :braille
        end
      end

      private def to_xscale(s : String?) : Symbol
        case s
        when "identity" then :identity
        when "log10"    then :log10
        when "ln"       then :ln
        when "log2"     then :log2
        when "sqrt"     then :sqrt
        when "cbrt"     then :cbrt
        else                 :identity
        end
      end

      private def to_closed(s : String?) : Symbol
        s == "right" ? :right : :left
      end

      private def resolve_color(color : (String | UInt32)?, default : Symbol) : Symbol | UInt32
        case c = color
        when UInt32 then c
        when String then to_color_sym(c, default)
        else             default
        end
      end

      private def resolve_color_sym(color : (String | UInt32)?, default : Symbol) : Symbol | UInt32
        resolve_color(color, default)
      end

      private def to_color_sym(s : String, default : Symbol) : Symbol
        case s
        when "green"   then :green
        when "blue"    then :blue
        when "red"     then :red
        when "yellow"  then :yellow
        when "cyan"    then :cyan
        when "magenta" then :magenta
        when "white"   then :white
        when "black"   then :black
        when "auto"    then :auto
        when "normal"  then :normal
        else                default
        end
      end

      private def symbol_chars(sym : String?) : Array(Char)?
        return unless sym

        chars = sym.chars
        chars.empty? ? nil : [chars.first]
      end

      private def check_series_size(data : Data, fmt : String)
        series = data.series
        if series.size == 1
          STDERR.puts "YouPlot2: There is only one series of input data. Please check the delimiter."
          STDERR.puts ""
          STDERR.puts "Headers: #{data.headers.inspect.colorize(:magenta)}"
          STDERR.puts "The first item is: #{series[0][0].inspect.colorize(:magenta)}"
          STDERR.puts "The last item is : #{series[0][-1].inspect.colorize(:magenta)}"
          exit 1
        end
        if fmt == "xyxy" && series.size.odd?
          STDERR.puts "YouPlot2: In the xyxy format, the number of series must be even."
          STDERR.puts ""
          STDERR.puts "Number of series: #{series.size.to_s.colorize(:magenta)}"
          STDERR.puts "Headers: #{data.headers.inspect.colorize(:magenta)}"
          exit 1
        end
      end

      private def plot_fmt(data : Data, fmt : String, method1 : Symbol,
                           params : Parameters) : ::UnicodePlot::Plot
        case fmt
        when "xyy"  then plot_xyy(data, method1, params)
        when "xyxy" then plot_xyxy(data, method1, params)
        else
          raise ArgumentError.new("Unknown format: #{fmt}")
        end
      end

      private def plot_xyy(data : Data, method1 : Symbol,
                           params : Parameters) : ::UnicodePlot::Plot
        headers = data.headers
        series = data.series.map { |ser| ser.map { |v| to_f64_or_zero(v) } }

        if headers
          params.name ||= headers[1]
          params.xlabel ||= headers[0]
        end

        xlim = params.xlim || auto_lim(series[0])
        ylim = params.ylim || auto_lim(series[1..].flat_map(&.itself))

        plot = call_plot(method1, series[0], series[1], params, xlim, ylim,
          name: params.name || "")
        if series.size > 2
          (2...series.size).each do |i|
            nm = headers ? headers[i] : ""
            call_plot_bang(method1, plot, series[0], series[i], name: nm)
          end
        end
        plot
      end

      private def plot_xyxy(data : Data, method1 : Symbol,
                            params : Parameters) : ::UnicodePlot::Plot
        headers = data.headers
        float_series = data.series.map { |ser| ser.map { |v| to_f64_or_zero(v) } }
        pairs = float_series.each_slice(2).to_a

        xlim = params.xlim || auto_lim(pairs.flat_map(&.first))
        ylim = params.ylim || auto_lim(pairs.flat_map(&.last))

        params.name ||= headers[0] if headers
        x1, y1 = pairs[0]
        plot = call_plot(method1, x1, y1, params, xlim, ylim, name: params.name || "")

        pairs[1..].each_with_index do |(xi, yi), i|
          nm = headers ? headers[(i + 1) * 2] : ""
          call_plot_bang(method1, plot, xi, yi, name: nm)
        end
        plot
      end

      private def auto_lim(arr : Array(Float64)) : {Float64, Float64}
        return {0.0, 0.0} if arr.empty?
        {arr.min, arr.max}
      end

      private def to_f64_or_zero(v : String?) : Float64
        return 0.0 unless v
        v.to_f64? || 0.0
      end

      private def call_plot(method1 : Symbol,
                            x : Array(Float64), y : Array(Float64),
                            params : Parameters,
                            xlim : {Float64, Float64},
                            ylim : {Float64, Float64},
                            name : String) : ::UnicodePlot::Plot
        border = to_border(params.border, :solid)
        canvas = to_canvas(params.canvas)
        title = params.title || ""
        xlabel = params.xlabel || ""
        ylabel = params.ylabel || ""
        margin = params.margin || 3
        padding = params.padding || 1
        labels = params.labels != false
        color = resolve_color(params.color, :auto)
        grid = params.grid != false

        case method1
        when :lineplot
          ::UnicodePlot.lineplot(x, y,
            title: title, width: params.width, height: params.height,
            xlabel: xlabel, ylabel: ylabel,
            border: border, margin: margin, padding: padding,
            labels: labels, color: color, canvas: canvas,
            xlim: xlim, ylim: ylim, grid: grid, name: name)
        when :scatterplot
          ::UnicodePlot.scatterplot(x, y,
            title: title, width: params.width, height: params.height,
            xlabel: xlabel, ylabel: ylabel,
            border: border, margin: margin, padding: padding,
            labels: labels, color: color, canvas: canvas,
            xlim: xlim, ylim: ylim, grid: grid, name: name)
        when :densityplot
          ::UnicodePlot.densityplot(x, y,
            title: title, width: params.width, height: params.height,
            xlabel: xlabel, ylabel: ylabel,
            border: border, margin: margin, padding: padding,
            labels: labels, color: color,
            xlim: xlim, ylim: ylim, name: name)
        else
          raise ArgumentError.new("Unknown plot method: #{method1}")
        end
      end

      private def call_plot_bang(method1 : Symbol,
                                 plot : ::UnicodePlot::Plot,
                                 x : Array(Float64), y : Array(Float64),
                                 name : String) : ::UnicodePlot::Plot
        case method1
        when :lineplot
          ::UnicodePlot.lineplot!(plot, x, y, name: name)
        when :scatterplot
          ::UnicodePlot.scatterplot!(plot, x, y, name: name)
        when :densityplot
          ::UnicodePlot.densityplot!(plot, x, y, name: name)
        else
          raise ArgumentError.new("Unknown plot! method: #{method1}")
        end
      end
    end
  end
end

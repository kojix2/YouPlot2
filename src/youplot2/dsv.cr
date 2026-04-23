require "csv"
require "colorize"

module YouPlot2
  # Parses DSV (delimiter-separated values) text into a Data struct.
  module DSV
    extend self

    def parse(input : String, delimiter : Char, headers : Bool?, transpose : Bool) : Data
      raw = CSV.parse(input, separator: delimiter)
      rows : Array(Array(String?)) = raw.map { |row| row.map { |v| v.as(String?) } }

      # Remove blank rows
      rows.reject! { |row| row.empty? || row.all?(Nil) }

      hdrs = get_headers(rows, headers, transpose)
      series = get_series(rows, headers, transpose)

      if hdrs
        STDERR.puts "Headers contains empty string in it.".colorize(:magenta) if hdrs.any?(&.empty?)

        h_size = hdrs.size
        s_size = series.size

        if h_size > s_size
          STDERR.puts "The number of headers is greater than the number of series.".colorize(:magenta)
          exit 1
        elsif h_size < s_size
          STDERR.puts "The number of headers is less than the number of series.".colorize(:magenta)
          exit 1
        end
      end

      Data.new(hdrs, series)
    end

    # Transpose arrays of (possibly) different sizes
    private def transpose2(arr : Array(Array(String?))) : Array(Array(String?))
      max_len = arr.max_of?(&.size) || 0
      Array(Array(String?)).new(max_len) do |i|
        arr.map { |row| row[i]? }
      end
    end

    private def get_headers(rows : Array(Array(String?)), headers : Bool?, transpose : Bool) : Array(String)?
      return unless headers

      if transpose
        # first element of each row becomes a header
        rows.map { |row| row[0]? || "" }
      else
        rows[0].map { |v| v || "" }
      end
    end

    private def get_series(rows : Array(Array(String?)), headers : Bool?, transpose : Bool) : Array(Array(String?))
      unless headers
        return rows if transpose
        return transpose2(rows)
      end

      # headers present but no data rows
      return Array(Array(String?)).new(rows[0].size) { [] of String? } if rows.size == 1

      if transpose
        rows.map { |row| row[1..].map { |v| v.as(String?) } }
      else
        transpose2(rows[1..])
      end
    end
  end
end

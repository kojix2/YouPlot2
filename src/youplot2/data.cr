module YouPlot2
  # Parsed DSV data: optional header row + columns of string values
  # record Data(Array(String)? headers, Array(Array(String?)) series)
  struct Data
    getter headers : Array(String)?
    getter series : Array(Array(String?))

    def initialize(@headers : Array(String)?, @series : Array(Array(String?)))
    end
  end
end

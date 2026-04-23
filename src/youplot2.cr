require "unicode_plot"

require "./youplot2/data"
require "./youplot2/parameters"
require "./youplot2/options"
require "./youplot2/dsv"
require "./youplot2/backends/processing"
require "./youplot2/backends/unicode_plot"
require "./youplot2/parser"
require "./youplot2/command"

module YouPlot2
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
end

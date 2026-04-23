module YouPlot2
  # Command-line options that are not plot parameters
  class Options
    property delimiter : Char = '\t'
    property? transpose : Bool = false
    property headers : Bool? = nil
    # IO for --pass.
    property pass : IO? = nil
    # Path for --pass FILE.
    property pass_path : String? = nil
    # IO for plot output.
    property output : IO = STDERR
    # Path for --output FILE.
    property output_path : String? = nil
    property fmt : String = "xyy"
    property? progressive : Bool = false
    property? reverse : Bool = false
    property? color_names : Bool = false
    property? debug : Bool = false

    def initialize
    end
  end
end

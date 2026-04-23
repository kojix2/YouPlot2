module YouPlot2
  # UnicodePlot plot parameters (mirrors Ruby YouPlot2::Parameters)
  class Parameters
    property title : String?
    property width : Int32?
    property height : Int32?
    property border : String?
    property margin : Int32?
    property padding : Int32?
    property color : (String | UInt32)?
    property xlabel : String?
    property ylabel : String?
    property labels : Bool?
    property symbol : String?
    property xscale : String?
    property nbins : Int32?
    property closed : String?
    property canvas : String?
    property xlim : Tuple(Float64, Float64)?
    property ylim : Tuple(Float64, Float64)?
    property grid : Bool?
    property name : String?

    def initialize
    end
  end
end

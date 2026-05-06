module YouPlot2
  class Error < Exception
    getter exit_code : Int32

    def initialize(message : String, @exit_code : Int32 = 1, cause : Exception? = nil)
      super(message, cause: cause)
    end
  end

  class UsageError < Error
  end

  class InputError < Error
  end

  class DataError < Error
  end

  class PlotError < Error
  end
end

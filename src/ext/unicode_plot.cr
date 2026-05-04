module UnicodePlot
  def show_plot(io : IO, p : Plot, *, use_color : Bool) : Nil
    _show_plot(io, p, use_color)
  end
end

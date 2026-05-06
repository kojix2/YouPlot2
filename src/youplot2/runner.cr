module YouPlot2
  def self.run(argv : Array(String) = ARGV.dup, stderr : IO = STDERR) : Int32
    Command.new(argv).run
    0
  rescue ex : Error
    stderr.puts "YouPlot2: #{ex.message}"
    ex.exit_code
  rescue ex : IO::Error
    stderr.puts "YouPlot2: I/O error: #{ex.message}"
    1
  rescue ex
    stderr.puts "YouPlot2: internal error: #{ex.class}: #{ex.message}"
    stderr.puts "Please rerun with --debug if the input is not sensitive, then report this issue."
    1
  end
end

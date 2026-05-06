require "./spec_helper"

describe "error handling" do
  it "turns command-line parser failures into usage errors" do
    params = YouPlot2::Parameters.new
    options = YouPlot2::Options.new
    parser = YouPlot2::Parser.new(["line", "--width", "wide"], params, options)

    ex = expect_raises(YouPlot2::UsageError) do
      parser.parse
    end
    message = ex.message || ""
    message.should contain("--width")
    message.should contain("integer")
  end

  it "reports malformed ranges as usage errors" do
    params = YouPlot2::Parameters.new
    options = YouPlot2::Options.new
    parser = YouPlot2::Parser.new(["line", "--xlim", "1"], params, options)

    ex = expect_raises(YouPlot2::UsageError) do
      parser.parse
    end
    message = ex.message || ""
    message.should contain("--xlim")
    message.should contain("comma-separated")
  end

  it "reports empty input as a data error" do
    ex = expect_raises(YouPlot2::DataError) do
      YouPlot2::DSV.parse("\n\n", '\t', nil, false)
    end
    (ex.message || "").should contain("no data")
  end

  it "reports missing input files as input errors" do
    path = temp_command_path("missing")

    ex = expect_raises(YouPlot2::InputError) do
      YouPlot2::Command.new(["line", path]).run
    end
    message = ex.message || ""
    message.should contain("failed to read")
    message.should contain(File.basename(path))
  end

  it "reports plot/data shape errors without leaking low-level exceptions" do
    data = YouPlot2::DSV.parse("1\n2\n", '\t', nil, false)

    ex = expect_raises(YouPlot2::DataError) do
      YouPlot2::Backends::UnicodePlot.scatter(data, YouPlot2::Parameters.new)
    end
    (ex.message || "").should contain("only one data series")
  end

  it "catches application errors at the top level" do
    stderr = IO::Memory.new

    status = YouPlot2.run(["line", "--width", "wide"], stderr: stderr)

    status.should eq(1)
    stderr.to_s.should contain("YouPlot2:")
    stderr.to_s.should contain("--width")
  end
end

require "./spec_helper"

describe YouPlot2::Parser do
  it "parses common and subcommand options after command" do
    argv = [
      "line",
      "-d,",
      "-w", "50",
      "-h", "15",
      "-t", "AirPassengers",
      "--xlim", "1950,1960",
      "--ylim", "0,600",
    ]

    params = YouPlot2::Parameters.new
    options = YouPlot2::Options.new
    parser = YouPlot2::Parser.new(argv, params, options)

    parser.parse

    parser.command.should eq("line")
    options.delimiter.should eq(',')
    params.width.should eq(50)
    params.height.should eq(15)
    params.title.should eq("AirPassengers")
    params.xlim.should eq({1950.0, 1960.0})
    params.ylim.should eq({0.0, 600.0})
    parser.input_files.should eq([] of String)
  end

  it "parses common options before subcommand" do
    argv = [
      "-d,",
      "line",
      "--xlim", "1,2",
      "input.csv",
    ]

    params = YouPlot2::Parameters.new
    options = YouPlot2::Options.new
    parser = YouPlot2::Parser.new(argv, params, options)

    parser.parse

    parser.command.should eq("line")
    options.delimiter.should eq(',')
    params.xlim.should eq({1.0, 2.0})
    parser.input_files.should eq(["input.csv"])
  end

  it "does not create output or pass files while parsing" do
    output_path = File.join(Dir.tempdir, "youplot2-parser-output-#{Process.pid}-#{Random.rand(1_000_000)}.txt")
    pass_path = File.join(Dir.tempdir, "youplot2-parser-pass-#{Process.pid}-#{Random.rand(1_000_000)}.txt")

    argv = ["line", "--output", output_path, "--pass", pass_path, "input.csv"]

    params = YouPlot2::Parameters.new
    options = YouPlot2::Options.new
    parser = YouPlot2::Parser.new(argv, params, options)

    begin
      parser.parse

      options.output_path.should eq(output_path)
      options.pass_path.should eq(pass_path)
      File.exists?(output_path).should be_false
      File.exists?(pass_path).should be_false
    ensure
      File.delete(output_path) if File.exists?(output_path)
      File.delete(pass_path) if File.exists?(pass_path)
    end
  end
end

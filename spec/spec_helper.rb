$stdin = File.new("/dev/null")

require "rubygems"
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "xively-cli"
require "rspec"
require 'coveralls'
Coveralls.wear!

def execute(command_line)
  args = command_line.split(" ")
  command = args.shift

  Xively::Command.load
  object, method = Xively::Command.prepare_run(command, args)

  original_stdin, original_stderr, original_stdout = $stdin, $stderr, $stdout

  $stdin  = captured_stdin  = StringIO.new
  $stderr = captured_stderr = StringIO.new
  $stdout = captured_stdout = StringIO.new

  begin
    object.send(method)
  rescue SystemExit
  ensure
    $stdin, $stderr, $stdout = original_stdin, original_stderr, original_stdout
    Xively::Command.current_command = nil
  end

  [captured_stderr.string, captured_stdout.string]
end

def run(command_line)
  capture_stdout do
    begin
      Xively::CLI.start(*command_line.split(" "))
    rescue SystemExit
    end
  end
end

alias xively run

def capture_stderr(&block)
  original_stderr = $stderr
  $stderr = captured_stderr = StringIO.new
  begin
    yield
  ensure
    $stderr = original_stderr
  end
  captured_stderr.string
end

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = captured_stdout = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  captured_stdout.string
end

def stub_tcp_socket
  TCPSocket.stub(:new).and_return(MockTCPSocket.new)
end

class MockTCPSocket
  def puts(msg)
  end

  def gets
  end

  def close
  end
end

RSpec.configure do |config|
  config.color_enabled = true
  config.before { Xively::Client.stub(:post) }
end

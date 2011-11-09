class BigBlueButtonBot
  BOT_FILENAME = "bbbBot.jar"
  @@pids = []

  def initialize(server, meeting, count=1)
    # note: fork + exec with these parameters was the only solution found to run the command in background
    # and be able to wait for it (kill it) later on (see BigBlueButtonBot.finalize)
    pid = Process.fork do
      bot_file = File.join(File.dirname(__FILE__), BOT_FILENAME)
      exec("java", "-jar", "#{bot_file}", "-s", "#{server}", "-m", "#{meeting}", "-n", "#{count}", "-q")
      # IO::popen("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # exec(["java", "-jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null"])
      # exec("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # Process.exit!
    end
    wait_bot_startup
    @@pids << pid
  end

  def self.finalize
    @@pids.each do |pid|
      p = Process.kill("TERM", pid)
      Process.detach(pid)
    end
  end

  def wait_bot_startup
    sleep 3 # TODO: find a better way to wait for the bot
  end
end

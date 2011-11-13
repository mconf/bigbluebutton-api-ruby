class BigBlueButtonBot
  BOT_FILENAME = "bbb-bot.jar"
  @@pids = []

  def initialize(api, meeting, count=1)
    server = parse_server_url(api.url)

    # note: fork + exec with these parameters was the only solution found to run the command in background
    # and be able to wait for it (kill it) later on (see BigBlueButtonBot.finalize)
    pid = Process.fork do
      bot_file = File.join(File.dirname(__FILE__), BOT_FILENAME)
      exec("java", "-jar", "#{bot_file}", "-s", "#{server}", "-m", "#{meeting}", "-n", "#{count}")
      # IO::popen("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # exec(["java", "-jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null"])
      # exec("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # Process.exit!
    end
    @@pids << pid

    wait_bot_startup(api, meeting, 15)
  end

  def self.finalize
    @@pids.each do |pid|
      p = Process.kill("TERM", pid)
      Process.detach(pid)
    end
    @@pids.clear
  end

  def parse_server_url(full_url)
    uri = URI.parse(full_url)
    uri_s = uri.scheme + "://" + uri.host
    uri_s = uri_s + ":" + uri.port.to_s if uri.port != uri.default_port
    uri_s
  end

  def wait_bot_startup(api, meeting, timeout=20)
    # we wait until the meeting is running
    # TODO: if the meeting was already running it will not wait properly
    Timeout::timeout(timeout) do
      running = false
      while !running
        sleep 1
        response = api.get_meetings
        hash = response[:meetings].select!{ |m| m[:meetingID] == meeting }[0]
        running = hash[:running]
      end
    end
  end
end

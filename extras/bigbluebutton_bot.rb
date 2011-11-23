class BigBlueButtonBot
  BOT_FILENAME = "bbb-bot.jar"
  @@pids = []

  def initialize(api, meeting, salt="", count=1, timeout=20)
    bot_file = File.join(File.dirname(__FILE__), BOT_FILENAME)
    unless File.exist?(bot_file)
      throw Exception.new(bot_file + " does not exists. See download_bot_from.txt and download the bot file.")
    end

    server = parse_server_url(api.url)

    # note: fork + exec with these parameters was the only solution found to run the command in background
    # and be able to wait for it (kill it) later on (see BigBlueButtonBot.finalize)
    pid = Process.fork do
      exec("java", "-jar", "#{bot_file}", "-s", "#{server}", "-p", "#{salt}", "-m", "#{meeting}", "-n", "#{count}")

      # other options that didn't work:
      # IO::popen("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # exec(["java", "-jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null"])
      # exec("java -jar #{bot_file} -s \"#{server}\" -m \"#{meeting}\" -n #{count} >/dev/null")
      # Process.exit!
    end
    @@pids << pid

    wait_bot_startup(api, meeting, count, timeout)
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

  # wait until the meeting is running with a certain number of participants
  def wait_bot_startup(api, meeting, participants, timeout=20)
    Timeout::timeout(timeout) do
      stop_wait = false
      while !stop_wait
        sleep 1

        # find the meeting and hope it is running
        response = api.get_meetings
        selected = response[:meetings].reject!{ |m| m[:meetingID] != meeting }
        if selected and selected.size > 0 and selected[0][:running]

          # check how many participants are in the meeting
          pass = selected[0][:moderatorPW]
          response = api.get_meeting_info(meeting, pass)
          stop_wait = response[:participantCount] >= participants
        end
      end
    end
  end
end

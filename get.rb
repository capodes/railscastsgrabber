require 'typhoeus'
require 'net/http'
require 'uri'
#railscasts grabber
total_episodes = 417
@threads = 5
@cookie = 'YOUR COOKIE'

fs = []
hydra = Typhoeus::Hydra.new(max_concurrency: 5)
total_episodes.times{|i|
  i = i + 1
  request = Typhoeus.get("http://railscasts.com/episodes/#{i}", headers: {Cookie: @cookie})
  response = request
  link = response.headers['Location']
  link = "http://media.railscasts.com/assets/episodes/videos/00" + response.headers['Location'].gsub(/.*\/(.*)/, '\\1') + ".mp4" if response.headers['Location'].scan(/.*\/(\d+)-/)[0][0].to_i < 10
  link = "http://media.railscasts.com/assets/episodes/videos/0" + response.headers['Location'].gsub(/.*\/(.*)/, '\\1') + ".mp4" if response.headers['Location'].scan(/.*\/(\d+)-/)[0][0].to_i > 10
  link = "http://media.railscasts.com/assets/episodes/videos/" + response.headers['Location'].gsub(/.*\/(.*)/, '\\1') + ".mp4" if response.headers['Location'].scan(/.*\/(\d+)-/)[0][0].to_i > 99
  filename = URI.parse(link).path.to_s.gsub(/\/.*\/(.*)/, "\\1")
  begin
    if File.open('casts/' + filename, 'r').size > 0
      puts "casts/#{filename} exists."
      next
    end
  rescue
  end
  f = File.open('casts/' + filename, 'w')
  begin
    fz = Typhoeus.head(link, headers: {Cookie: @cookie})
    next if fz.headers['Content-Length'].to_i == f.size
    puts "File: #{filename} [ #{fz.headers['Content-Length'].to_i/1000/1000} MB ]"
    fs[i] = Typhoeus::Request.new(
        link,
        headers: {Cookie: @cookie}
    )
    fs[i].on_complete do |response|
      t = File.open('casts/' + response.effective_url.gsub(/.*\/(.*\.mp4)/, "\\1"), 'w')
      puts "File: %s OK" % response.effective_url.gsub(/.*\/(.*\.mp4)/, "\\1")
      t.write(response.body)
      t.close
    end
    hydra.queue fs[i]
    if hydra.queued_requests.count() == @threads
      puts "Running #{@threads} threads"
      hydra.run
    end
  ensure
    f.close
  end
}
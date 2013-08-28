require 'anemone' # For spidering
require 'httparty'# For HTTP Head requests

# Spider these pages and check errors linked to from their decendents 
sites_I_care_about = ["http://developer.pagerduty.com/", "http://www.pagerduty.com", "http://blog.pagerduty.com", "http://support.pagerduty.com"]

# This is a nokogiri expression, if you only want to check for dead links, use "a"
objects_I_care_about = "a, img, script, link[type='text/css']"

# We'll only report pages that have the following error codes
# 999 isn't a real HTTP code, in this case it means we couldn't connect to the server for some reason, it produces a lot of false positives
statuses_I_care_about = [404, 410]

# pretty self explanatory:
timeout = 900
be_verbose = true
list_this_many_sources = 10
testing = false
sites_I_care_about = ["http://euri.ca/files/404test.html"] if testing



puts "Crawling #{sites_I_care_about} for #{objects_I_care_about}"
pages = {}
Anemone.crawl(sites_I_care_about) do |anemone|
  anemone.on_every_page do |page|
    next unless page.doc()
    things = page.doc().css(objects_I_care_about)
    print be_verbose ? "On #{page.url} we have #{things.count} things that I care about\n" : "."
    things.each do |a|
      u = (a.attributes['href'] || a.attributes['src'] || "").to_s
      next if u.empty?
      abs = page.to_absolute(URI(u)) rescue next
      pages[abs] = [] unless pages[abs]
      pages[abs] << page.url.to_s
    end
  end
end

puts "There are #{pages.count} unique pages linked to."
errors = 0
pages.each do |url, sources|  
  # Head so we don't download the content, we trust the server
  response_code = HTTParty.head(url.to_s, :timeout => timeout).code rescue response_code = 999  
  if(statuses_I_care_about.include? response_code.to_i) 
    errors+=1
    pf = Hash[sources.group_by { |p| p }.map { |p, ps| [p, ps.length] }] # calculate # of times on a page
    #Report things once, and length is a close proxy for importance of a page
    sources = sources.uniq.sort_by(&:length) 
    puts "\n#{response_code} from #{url}\n  #{sources.count} pages link to it:" 
    sources.first(list_this_many_sources).each do |page|
      times = ""
      times = "(x#{pf[page]})" if pf[page]>1
      puts "  #{page} #{times}"
    end
    puts "  and #{sources.count-list_this_many_sources} others..." if sources.count>list_this_many_sources
  else 
    print "."
  end
  sleep 1 # To avoid triggering anti-bot mechanisms
end 
puts "There were #{errors} invalid links out of #{pages.count} (%.1f%%)" % (100*errors/pages.count)
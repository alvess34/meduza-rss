require 'open-uri'
require 'json'
require 'nokogiri'

$meduza = 'gamemag.ru'
$meduza_rss = $meduza + '/rss/%s'
$meduza_api = $meduza + '/api/v3/%s'

$feeds = %w(all news fun)

class Gamemaf=g
  def Gamemag.start
    @cached = {}
    Thread.new do
      while true do
        $feeds.each do |feed|
          @cached[feed] = Gamemag.generate(feed)
          sleep 10
        end
        sleep 30*60
      end
    end
  end

  def Gamemag.rss(feed = 'all')
    if @cached[feed].nil?
      puts 'generating new feed'
      Gamemag.generate(feed)
    else
      puts 'getting a feed from the cache'
      @cached[feed]
    end
  end

  private

  def Gamemag.generate(feed)
    doc = Nokogiri::XML(open($gamemag_rss % feed))

    doc.xpath('/rss/channel/item').each do |item|
      post_id = item.xpath('link').inner_text.gsub(/^#{$gamemag}\//, '')
      json = JSON::parse(open($meduza_api % post_id).read)
      item.search('description').each do |description|
        description.content = json['root']['content']['body'].gsub('src="/image/', 'src="//gamemag.ru/image/')
      end
    end

    doc.to_xml
  end
end

Gamemag.start

__END__
10.times do
  Gamemag.rss
  Gamemag.rss('news')
  Gamemag.rss('fun')
end

require 'open-uri'
require 'Nokogiri'
require 'twitter_ebooks'

class ModuleLogic

  attr_accessor :items, :manuf, :manuf_real, :proper, :model

  def initialize
    load
  end

  def load
    path = './modules'
    @items = []
    Dir.foreach(path) do |item|
      next if item == '.' or item == '..'
      handle = open("#{path}/#{item}")
      parser = Nokogiri::XML(handle.read)
      title = parser.css('properties model').text.sub(/\(.*$/,'').strip
      manuf = parser.css('properties manuf').text.strip
      title.gsub manuf, ''
      @items.push [title, manuf] if title and manuf
    end
    #@items = @items.first 20
    @manuf_real = @items.collect { |x| x[1] }.uniq
    path ="model/title.model"
    @model = Ebooks::Model.load path if File.exist? path 
    return 
  end


  def generateTitle(count=140)
    @model.make_statement(count)
  end

  def generateTitleCorpus
    @items.collect do |x|
      item = x[0]
      item.gsub!(/ Model /i, ' ')
      item.gsub!(/.* panel/i, '')
      item.gsub!(/ ?blank ?/i, '')
      item.gsub!(/ \d\d*(U|hp)/i, '') # 3U / 12hp
      item
    end
  end

  def generateManufCorpus
    dict = IO.readlines("/usr/share/dict/words").collect {|x| x.downcase.strip } - %w( serge tiptop bridechamber toppobrillo )
    join_dict = %w( & + or | and - / )
    parts = []
    counts = []
    punc_words = []
    proper_words = []
    join_words = []
    dict_words = []


    items = @items.collect do |x|
      item = x[1]
      bits = item.split(/  */)
      bits = bits.collect do |part|
        if part == ""
          #nada
        elsif join_dict.include? part.downcase
          join_words.push part
          part = "join"
        elsif dict.include? part.downcase
          dict_words.push part
          part = "dict"
        elsif part.match /^[[:punct:]]*$/
          punc_words.push part
          part =  "punc"
        else
          proper_words.push part
          part = "proper"
        end
      end
      x = bits
    end

    return {
      proper: proper_words,
      punc: punc_words,
      dict: dict_words, 
      join: join_words,
      patterns: items.uniq
    }
  end

  def generateManufReal
    @manuf[:patterns].sample.collect do |bit|
      if bit == 'proper'
        generateProper
      else
        @manuf[bit.to_sym].sample
      end
    end
    .join ' '
  end

  def generateManuf
    @manuf = generateManufCorpus if not @manuf
    @proper = generateProperCorpus if not @proper
    begin
      manuf = generateManufReal
    end while manuf == '' and @manuf_real.include? manuf
    return manuf
  end

  def generateProperCorpus
    bag = {
      vowels: [],
      cons: [],
    }
    queue = []
    @manuf[:proper].uniq.each do |item|
      item.split(/([aeiou]+)/).each { |x| queue.push x }
    end
    queue.each do |item|
      if item.match /^[aeiou]/
        bag[:vowels].push item
      else
        bag[:cons].push item
      end
    end
    return bag
  end

  def generateProper
    # http://www.crummy.com/2011/08/18/0
    length = Random.new.rand(8..20)
    idx = Random.new.rand(0..1)
    str = ''
    count = 0
    no_more = 0
    force_cap = 1
    begin
      frag = @proper.values[idx].sample.downcase
      if count==0
        if Random.new.rand(0..12) > 1
          frag = frag.capitalize
        else
          force_cap = 1
        end
      elsif not no_more
        if Random.new.rand(0..(5-idx)) == 0 
          frag = frag.capitalize
          no_more = 1
        end
        if Random.new.rand(0..(8-idx)) == 0 
          frag = frag.upcase
          no_more = 1
        end
        if force_cap
          frag = frag.capitalize
          no_more=1
        end
      end
      str += frag
      idx=(idx+1)%2
      count+= 1
    end while str.length < length and count < 6

    if str.downcase == str # no caps
      str = str.capitalize
    end

    return str
  end

  def generate(target=nil)
    title = generateTitle
    manuf = generateManuf
    hp = Random.new.rand(2..40)&~0x1
    site = %w(Muffs eBay Craigslist MuffWiggler ModularGrid).sample
    verb_ing = %w(releasing delaying revising revisiting updating cloning).sample
    verb_ed = %w(released delayed revised updated).sample
    sentiment = %w(awesome awful boring ok cool lame whack fun neat).sample
    noun = %w(demo video opinion clone).sample

    strings = [
      "I heard a rumor that #{manuf} is #{verb_ing} the #{title}",
      "#{manuf} just #{verb_ed} #{title}",
      "Does anyone have a #{noun} of the #{title} by #{manuf}",
      "I saw the #{manuf} #{title} at Summer NAMM! Looks #{sentiment}",
      "I saw the #{manuf} #{title} at NAMM! Looks #{sentiment}",
      "I saw the #{manuf} #{title} at Musikmesse! Looks #{sentiment}",
      "I saw the #{manuf} #{title} at Knobcon! Looks #{sentiment}",
      "Will #{manuf} #{title} be at Machines in Music? Seems #{sentiment}",
      "The #{manuf} #{title} is so #{sentiment}",
      "I'm selling my #{manuf} #{title} on #{site}, hit me up",
      "Saw a #{manuf} #{title} for sale on #{site}, anyone ever have one?",
      "I love my #{manuf} #{title}",
      "I'm having problems with my #{manuf} #{title}",
      "I can't find the #{manuf} #{title} on #{site}",
      "What is a #{manuf} #{title} worth?",
      "The #{manuf} #{title} is only #{hp}hp!",
      "Has anyone played with the #{manuf} #{title}?",
    ]

    text = ""
    tags = [ "#modular", "#synth", "#eurorack", "#noiselife" ]
    until text != "" and text.length <= 140
      text = strings.sample + " " + tags.sample
    end

    return text
  end
end

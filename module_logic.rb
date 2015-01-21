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
    @model = Ebooks::Model.load("model/title.model")
    return 
  end


  def generateTitle(count=140)
    @model.make_statement(count)
  end

  def generateTitleCorpus
    items.collect do |x|
      x[0]
    end
  end

  def generateManufCorpus
    dict = IO.readlines("/usr/share/dict/words").collect {|x| x.downcase.strip }
    join_dict = [ "&", "+", "or", "|", "and", "-", "/" ]
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
    end while manuf == '' and  @manuf_real.include? manuf
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
    return str
  end

  def generate(target=nil)
    title = generateTitle
    manuf = generateManuf
    hp = Random.new.rand(2..40)&~0x1

    strings = [
      "I heard a rumor that #{manuf} is delaying the #{title}",
      "Just announced #{manuf} #{title}",
      "Does anyone have a demo of the #{title} by #{manuf}",
      "Looking forward to seeing the #{manuf} #{title} at NAMM!",
      "I'm selling my #{manuf} #{title} on Muffs, hit me up",
      "Saw a #{manuf} #{title} for sale on craigslist, anyone ever have one?",
      "I love my #{manuf} #{title}",
      "I'm having problems with my #{manuf} #{title}",
      "I can't find the #{manuf} #{title} on ModularGrid",
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

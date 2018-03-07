require 'open-uri'
require 'nokogiri'
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


  def generateTitle(count=280)
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
    site = %w(Muffs Lines eBay Craigslist MuffWiggler ModularGrid).sample
    verb_ing = %w(releasing delaying revising revisiting updating cloning discontinuing).sample
    verb_ed = %w(released delayed revised updated canceled).sample
    sentiment = %w(awesome awful boring ok cool lame whack fun neat).sample
    sentiment_mod = ['sort of', 'kinda', 'very', 'not very', 'extremely', 'possibly', '', 'not', '', '', '', ''].sample
    noun = %w(demo video opinion clone).sample
    panel_type = %w(Grayscale black 5U 4U DIY).sample
    feature_noun = ["vactrols", "attenuverters", "attenuators",
      "banana jacks", "firmware updates", "updated firmware", "bugs", "source code available",
      "Rogan knobs", "touchplates", "an expansion header", "midi", "a DIN connector", "USB"].sample
    specific_feature_noun = ["vactrols", "attenuverters", "attenuators",
      "banana jacks", "Rogan knobs" "touchplates" ].sample
    property = ["open source", "already released", "available yet", "unreleased", "available",
      "discontinued", 'out of production', 'in production', "RoHS compliant"].sample
    convention = [
      "Summer NAMM",
      "NAMM",
      "Musikmesse",
      "Knobcon",
      "Machines in Music",
    ].sample
    problem_type = ["update", "power", "repair", "", "noise", "comprehension", "distortion" ].sample
    musician = [
      "Kaitlyn Aurelia Smith",
      "Alessandro Cortini",
      "Don Buchla",
      "Richard Devine",
      "Robert Moog",
      "Bob Moog",
      "Tonto's Expanding Head Band",
      "Baseck",
      "Dave Smith",
      "Kraftwerk",
      "Vince Clarke",
      "Aphex Twin",
      "Autechre",
      "Surgeon",
      "Boards of Canada",
      'Oval',
      "Plaid",
      "Vatican Shadow",
      "Prurient",
      "Jim O'Rourke",
      "Stereolab",
      "Richard D. James",
      "Grant Richter",
      "Wendy Carlos",
    ].sample


    strings = [
      "I heard that #{specific_feature_noun} are the key to #{manuf} #{title}",
      "I heard that #{specific_feature_noun} are the secret to #{manuf} #{title}",
      "#{specific_feature_noun.capitalize} are the secret to #{manuf} #{title}",
      "#{specific_feature_noun.capitalize} are the key to #{manuf} #{title}",
      "The #{manuf} #{title} is #{["not",""].sample} #{sentiment_mod} #{sentiment} if you want to sound like #{musician}",
      "If you want to sound like #{musician}, try using a #{title}",
      "If you want to sound like #{musician}, try using a #{manuf} #{title}",
      "If you want to sound like #{musician}, use a #{title}",
      "If you want to sound like #{musician}, use a #{manuf} #{title}",
      "Did #{musician} use a #{title}?",
      "Did #{musician} use a #{manuf} #{title}?",
      "Did #{musician} ever use a #{title}?",
      "Did #{musician} ever use a #{manuf} #{title}?",
      "Is anyone having #{problem_type} problems with their #{manuf} #{title}?",
      "Having #{problem_type} problems with my #{manuf} #{title}",
      "Having #{problem_type} issues with my #{manuf} #{title}",
      "Does #{specific_feature_noun} fix #{problem_type} issues with the #{manuf} #{title}?",
      "Does #{specific_feature_noun} fix #{problem_type} issues with the #{title}?",
      "Would #{specific_feature_noun} solve #{problem_type} problems with the #{manuf} #{title}?",
      "Would #{specific_feature_noun} solve #{problem_type} problems with the #{title}?",
      "I wish #{manuf} had included #{specific_feature_noun} on the #{title}",
      "#{manuf} will #{["not",""].sample} include #{specific_feature_noun} on their #{title}",
      "I need a #{panel_type} panel for my #{manuf} #{title}",
      "Does anyone have a #{panel_type} panel for a #{manuf} #{title}?",
      "Just installed #{panel_type} panel for a #{manuf} #{title}?",
      "Does #{manuf} #{title} have #{feature_noun}?",
      "#{manuf} #{title} has #{feature_noun}; #{sentiment_mod} #{sentiment}",
      "Is #{manuf} #{title} #{property}?",
      "Anyone know if #{manuf} #{title} is #{property}?",
      "Does anyone know if #{manuf} #{title} is #{property}?",
      "I heard a rumor that #{manuf} is #{verb_ing} the #{title}",
      "#{manuf} just #{verb_ed} #{title}",
      "Does anyone have a #{noun} of the #{title} by #{manuf}",
      "I saw the #{manuf} #{title} at #{convention}! Looks #{sentiment_mod} #{sentiment}",
      "Can't wait to see the #{manuf} #{title} at #{convention}.",
      "The #{manuf} #{title} is #{sentiment}",
      "I'm selling my #{manuf} #{title} on #{site}, hit me up",
      "Saw a #{manuf} #{title} for sale on #{site}, anyone ever have one?",
      "I love my #{manuf} #{title}",
      "I'm having #{problem_type} problems with my #{manuf} #{title}",
      "I can't find the #{manuf} #{title} on #{site}",
      "What is a #{manuf} #{title} worth?",
      "The #{manuf} #{title} is only #{hp}hp!",
      "Has anyone played with the #{manuf} #{title}?",
    ]

    text = ""
    tags = [ "#modular", "#synth", "#eurorack", "#noiselife", "🎛", '🎚', '👾', '👽' ]
    until text != "" and text.length <= 280
      text = strings.sample + " " + tags.sample
    end

    return text
  end
end

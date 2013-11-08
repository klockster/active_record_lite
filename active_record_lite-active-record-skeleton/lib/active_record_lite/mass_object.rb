class MassObject
  def self.my_attr_accessor(*args)
    my_attr_reader(*args)
    my_attr_setter(*args)
  end

  def self.my_attr_reader(*args)
    args.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end
  end

  def self.my_attr_setter(*args)
    args.each do |name|
      define_method("#{name}=") do |other|
        instance_variable_set("@#{name}",other)
      end
    end
  end
  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.
  def self.my_attr_accessible(*attributes)
    attributes.each do |attri|
      my_attr_accessor(attri)
      self.attributes << attri
    end
    #self.attributes << self
  end

  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes ||= []
  end

  def self.assoc_params
    @assoc_params ||= {}
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    results.map{ |params| self.new(params) }
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.keys.each do |key|
      if self.class.attributes.include?(key.to_sym)
        instance_variable_set("@#{key}",params[key])
      else
        raise "Cannot mass assign #{key}"
      end
    end
  end

end
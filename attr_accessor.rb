class Object
  def my_attr_accessor(*args)
    my_attr_reader(*args)
    my_attr_setter(*args)
  end

  def my_attr_reader(*args)
    args.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end
  end

  def my_attr_setter(*args)
    args.each do |name|
      define_method("#{name}=") do |other|
        instance_variable_set("@#{name}",other)
      end
    end
  end
end

class Fun
  my_attr_accessor :woo
end

f = Fun.new
f.woo = "Yes!"
p f.woo
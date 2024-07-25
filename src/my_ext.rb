class Object
  def first_only
    raise "bad size #{size}" if size != 1
    first
  end
end

File.class_eval do
  def self.create(f, b)
    File.open(f, "w") do |file|
      file.write(b)
    end
  end
end

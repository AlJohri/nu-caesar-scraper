require 'pdf-reader'

tmp = Array.new

File.open("nu_wholecat_201213.pdf", "rb") do |io|
    reader = PDF::Reader.new(io)
    buffer = PDF::Reader::Buffer.new(io)
    xref = PDF::Reader::XRef.new(io)
    parser = PDF::Reader::Parser.new(buffer)

    #parser.object(920,0)

    #xref.each { |x|
    #  puts x
    #}

    hash = reader.objects

    #key = hash[1000][:D][0]
    #puts key
    #puts key.is_a?(PDF::Reader::Reference)
    #puts hash[key]

    hash.each { |x|
      y = hash.object(x)
      tmp.push y if y.is_a?(Hash) and y.has_key?(:Title)
    }

end

File.open("test.txt", "w") { |x|
  x.write(tmp)
}          
require "ubb/version"


module Ubb
  class UbbFile
    def parse(filename)
      s = File.read(filename)
      eval(s)
    end

    def ubb(v)
      p v
    end



  end





end

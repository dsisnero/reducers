module Functional

  def complement
  lambda {|*args| not self.call(*args) }
  end

 def compose(other)
    lambda {|*args| call(other.call(*args)) }
  end

  def pipe(other)
    other.compose(self)
  end


  alias :* :compose
  alias :>> :pipe





end

class Proc; include Functional; end
class Method; include Functional; end

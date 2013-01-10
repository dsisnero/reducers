module Functional

  def identity
    ->x{ x}
  end


  module ClassMethods

    def compose(*proc_chain)
      proc_chain = proc_chain.first if proc_chain.first.class == Array
      proc_chain.reduce(->(x){x}){|result,p| result.compose(p)}
    end
  end




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

class Proc; include Functional; extend Functional::ClassMethods; end
class Method; include Functional; extend Functional::ClassMethods; end

require 'stunted'

# [1,2,3].into([]) do
# rmap[inc] >> filter[even?]
# end

#[1,2,3].xform( rmap[->(x){x+1}], filter[->(x){ x.even?}]).reduce(0){:+}



# compose = ->(f,g){ ->(*n){ f.(g.(*n))}}
module Enumerable

  def reducer(xf)
    Class.new do
      define_method :coll do
        self
      end
      define_method :reducer do |*args,&block|
        coll.reduce(*args,&block)
      end
    end
  end

end









class Proc

  def compose(other)
    lambda {|*args| call(other.call(*args)) }
  end

  def pipe(other)
    other.compose(self)
  end


  alias :* :compose
  alias :>> :pipe


end


module Reducers
  extend Stunted::Defn

  # (defn reducer
  #   ([coll xf]
  #    (reify
  #     clojure.core.protocols/CollReduce
  #     (coll-reduce [_ f1 init]
  #       (clojure.core.protocols/coll-reduce coll (xf f1) init)))))

  def reducer(coll,xf)
    Class.new do
      define_method :reduce do |init,coll,f1|
        coll.reduce(init,xf.(f1))
      end
    end
  end


  defn :coll_reduce, ->(coll, f1, init){
    coll.reduce(init,&f1)
  }

  defn :reducer, ->(coll,xf){

    ->(val,f1,init){
      coll.reduce(init,&( xf[f1]))
    }}


  defn :mapping, ->(f){
    ->(f1){
      ->(result,input){
        f1[result, f[input]]
      }

    }
  }

  defn :filtering, ->(pred){
    ->(f1){
      ->(result,input){
        if pred[input]
          f1[ result,input]
        else
          result
        end
      }
    }
  }



  defn :mapcatting, ->(f){
    ->(f1){
      ->(result,input){
        reduce[f1, result, f[input]]
      }
    }
  }

  defn :rmap, ->(f,coll){

    reducer[ coll, mapping[f]]
  }

  defn :rfilter, ->(pred,coll){
    reducer[ coll, filtering[pred]]
  }

  defn :rmapcat,->(f, coll){
    reducer[ coll, mapcatting[f]]
  }


end

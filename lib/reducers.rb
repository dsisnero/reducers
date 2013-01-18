require_relative 'reducers/functional'

module Enumerable

  def lazy2(&block)
    Reducers::Reducible.new(self)
  end

end


module Reducers

  VERSION = '0.0.5'

  module Transformers

    def map(&block)
      add_proc mapping(&block)
      self
    end

    def mash
            reduce({}) do |result, input|

        r = yield input

        case r
        when Hash
          nk, nv = *r.to_a[0]
        when Range
          nk, nv = r.first, r.last
        else
          nk, nv = *r
        end
        result[nk] = nv
        result
      end
    end

    def duplicate_on(&block)
      group_by(&block).map{|x| x[1]}.select{|x| x.size > 1}
    end

    def group_by()
      groups = reduce({}) do |h,i|
        result = yield i
        if h[result]
          h[result] << i
        else
          h[result] = [i]
        end
        h
      end
      groups.lazy2
    end

    def grep(patt)
      select{|x| x =~ patt}
    end

    def select(&block)
      add_proc filtering(&block)
      self
    end

    def reject(&block)
      add_proc filtering(&(block.complement))
      self
    end

    def mapcat(&block)
      add_proc mapcatting(&block)
      self
    end

    def take(n)
      add_proc taking(n)
      self
    end

    def drop(n)
      add_proc dropping(n)
      self
    end

    def take_while(&block)
      add_proc take_while_proc(&block)
      self
    end

    def drop_while(&block)
      add_proc drop_while_proc(&block)
      self
    end

    def flat_map(&block)
      map(&block).flatten
      self
    end


    def to_a
      force
    end

    protected

    def add_proc(proc)
      #  @chain = chain.compose(proc)
      @proc_chain << proc
    end

    def mapping()
      ->(f1){
        ->(result,input){
          mv = yield input
          f1[result,mv ]

        }

      }
    end

    def mashing
      ->(f1){

        ->(result,input){
          r = yield input
          h = {}
          case r
          when Hash
            nk, nv = *r.to_a[0]
          when Range
            nk, nv = r.first, r.last
          else
            nk, nv = *r
          end
          h[nk] = nv
          f1[result,h]
        }
      }
    end


    def taking(n)
      ->(f1){
        ->(result, input){
          n = n - 1
          if n >= 0
            f1[result, input]
          else
            throw(:reduced, result)
          end
        }
      }
    end

    def dropping(n)
      ->(f1){
        ->(result,input){
          n = n -1
          if n < 0
            f1[result,input]
          else
            result
          end
        }
      }
    end

    def take_while_proc()
      ->(f1){
        taking = true
        ->(result,input){
          taking = yield input
          if taking
            f1[result,input]
          else
            throw(:reduced,result)
          end
        }
      }
    end


    def drop_while_proc()
      ->(f1){
        dropping = true
        ->(result, input){

          if dropping
            dropping = yield input
          end
          if dropping
            result
          else
            f1[result,input]
          end
        }
      }
    end

    def filtering()
      ->(f1){
        ->(result,input){
          if yield input
            f1[ result,input]
          else
            result
          end
        }
      }
    end

    def parting()
      ->(f1){
        ->(result,input){
          if yield input
            [f1[result,input],result]
          else
            [result, f1[result,input]]
          end
        }}
    end


    def mapcatting()
      ->(f1){
        ->(result,input){
          mcv = yield input
          reduce[f1, result, mcv]
        }
      }
    end

    def flatmapping()
      ->(f1){
        ->(result,input){
          mcv = yield input
          f1[result, mcv.flatten]
        }
      }
    end

  end


  class Undefined; end

  class Reducible

    include Transformers


    # attr_reader :chain
    attr_reader :coll, :proc_chain

    def initialize(coll)
      @coll = coll
      @chain = ->x{x}
      @proc_chain = []
    end

    def reduce(init = nil, f= Undefined ,&block)
      if !block or !f == Undefined
        if f == Undefined
          f = init
          init = nil
        end

        reducer = f
      else
        reducer = chain.(block) if f == Undefined
      end

      result = catch(:reduced){

        if init
          coll.reduce(init,&reducer)
        else
          coll.reduce(&reducer)
        end
      }

    end

    def initialize_copy(source)
      super
      @proc_chain = @proc_chain.dup
    end

    def tee
      p2 = self.dup
      [self, p2]
    end

    def partition(&block)
      p1,p2 = tee
      [p1.select(&block), p2.reject(&block)]
    end

    def chain
      chain ||= Proc.compose(proc_chain)
    end


    def force
      reduce([]){|r,i| r << i ; r}
    end


  end
end


# (defn reducer
#   ([coll xf]
#    (reify
#     clojure.core.protocols/CollReduce
#     (coll-reduce [_ f1 init]
#       (clojure.core.protocols/coll-reduce coll (xf f1) init)))))

# def reducer(coll,xf)
#   Class.new do
#     define_method :reduce do |init,coll,f1|
#       coll.reduce(init,xf.(f1))
#     end
#   end
# end

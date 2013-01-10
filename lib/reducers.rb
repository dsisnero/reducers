require_relative 'reducers/functional'
#require 'pry'
# [1,2,3].into([]) do
# rmap[inc] >> filter[even?]
# end

#[1,2,3].xform( rmap[->(x){x+1}], filter[->(x){ x.even?}]).reduce(0){:+}



# compose = ->(f,g){ ->(*n){ f.(g.(*n))}}

module Enumerable

  def lazy2(&block)
    Reducers::Reducible.new(self)
  end

end


module Reducers

  module Transformers

    def map(p = nil, &block)
      proc = p || block
      add_proc mapping(proc)
      self
    end

    def filter(p = nil, &block)
      proc = p || block
      add_proc filtering(proc)
      self
    end

    def mapcat(&block)
      add_proc mapcatting(&block)
      self
    end

    def take(n)
      reduce([]) do |result, input|
        return result if n <= 0
        result << input
        n = n - 1
        result
      end
    end

    def take_while(&block)
      proc = p || block
      add_proc take_while_proc(proc)
    end

    def drop_while(&block)
      proc = p || block
      add_proc drop_while_proc(proc)
      self
    end

    def to_a
      force
    end

    protected

    def add_proc(proc)
      @chain = chain.compose(proc)
    end

   # def mapping_creater(fname)
    # Module.class_eval do

    #   name = generate_name
    #   define_method (:name) do |result,input|
    #     f1(result,yield input)
    #   end

    #   def "genname"(result,input)
    #     "#{f1}(result, "#{genname}"(input))
    #   end


    def mapping(f)
      ->(f1){
        ->(result,input){
          f1[result, f[input]]
        }

      }
    end

    def taking(n)
      ->(f1){
        ->(result, input){
          n = n - 1
          if n > 0
            f1[result, input]
          else
            return
          end
        }
      }
    end

    def nonfiltered_proc
      ->(f1){
        ->(result,input){
          f1[result,input]
        }}
    end

    def filtered_proc
      ->(f1){
        ->(result,input){
          result
        }}
    end

    def take_while_proc(pred)
      ->(f1){
        taking = true
        ->(result,input){
          if taking
            taking = pred[input]
          end

          if taking
            f1[result,input]
          else
            #break
            return result
          end
        }}
    end



    def drop_while_proc(pred)
     # dropping = true
      ->(f1){
        dropping = true
        ->(result, input){

          if dropping
            dropping = pred[input]
          end
          if dropping
            result
          else
            f1[result,input]
          end
        }
      }
    end

    def filtering(pred)
      ->(f1){
        ->(result,input){
          if pred[input]
            f1[ result,input]
          else
            result
          end
        }
      }
    end
    def mapcatting(f)
      ->(f1){
        ->(result,input){
          reduce[f1, result, f[input]]
        }
      }
    end

  end


class Undefined; end

  class Reducible

    include Transformers


    attr_reader :chain, :coll

    def initialize(coll)
      @coll = coll
      @chain = ->x{x}
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

      if init
        coll.reduce(init,&reducer)
      else
        coll.reduce(&reducer)
      end
    end


    def force
      reduce([]){|r,i| r << i ; r}
    end

    def partition(&block)
      r2 = self.dup
      rfilter(&block)
      [self.rfilter(&block), r2.rfilter( block.complement)]
    end



    # def proc_chain
    #   chain = ->(x){ x }
    #   chain = ->(a_proc){ chain.compose(a_proc)}
    # end





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



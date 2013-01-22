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

    def mash2(&block)
      add_proc mashing(&block)
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

    def flat_map(&block)
      add_proc mapcatting(&block)
      self
    end

    alias :mapcat :flat_map


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

    def sum_r
      reduce(0){|r,i| r + i}
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


    def reduce3(init,coll,&f1)
      coll.reduce(init,&f1)
    end


    def mapcatting()
      ->(f1){
        ->(result,input){
          mcv = yield input
          reduce3 result, mcv, &f1
        }
      }
    end

    def mashing
      ->(f1){
        hresult = {}

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
          reduce3 result, hresult.merge(h), &f1
        }
      }
    end

    # def parting()
    #   ->(f1){
    #     ->(result,input){
    #       if yield input
    #         [f1[result,input],result]
    #       else
    #         [result, f1[result,input]]
    #       end
    #     }}
    # end


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
          reduce3(init,@coll,&reducer)
        else
          reduce_no_init(@coll,&reducer)
        end
      }
    end



    # def reduce_no_init(&reducer,coll)
    #   coll.reduce(&reducer)
    # end

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

    def method_missing(*args,&block)
      @coll.send(*args,&block)
    end

  end
end

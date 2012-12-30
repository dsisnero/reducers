require 'stunted'


module Reducers
  extend Stunted::Defn


  defn :reducer, ->(coll,xf){

    ->(val,f1,init){
      coll.reduce(init)[&( xf[f1])]
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



end

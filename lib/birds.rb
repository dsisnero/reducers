require 'stunted'

module Quirky

  extend Stunted::Defn

  defn :thrush, ->(proc1) do
    ->(proc2) {
      ->(val){
        proc2.to_proc.(proc1.to_proc.(val))
      }
    }

  end

end

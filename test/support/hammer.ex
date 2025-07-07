defmodule ReqHammer.TestHammer do
  use Hammer, backend: :atomic, algorithm: :fix_window
end

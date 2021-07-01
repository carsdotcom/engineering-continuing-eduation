# engineering-continuing-education
Language agnostic repository for Cars.com engineers to post solutions to code exercises

## Submitting Solutions

Navigate to the challenge, set, and problem folder for the problem you are solving.

Add a file named for your solution group. For example, if I am solving with Paully Walnuts, I might add a file named: ck_pw_p1.ex to the folder: cryptopals/set1/challenge1/submitted_solutions/

For ease of development, I will write my application code and test in the same file.

Example file:

```elixir
defmodule Decode do
  def hello, do: "world"
end

ExUnit.start()

defmodule DecodeTest do
  use ExUnit.Case

  test "hello/0" do
    assert Decode.hello() == "world"
  end
end

```

### Running Tests

`$ elixir -r cryptopals/set1/challenge1/submitted_solutions/ck_pw_p1.ex`

Ref: https://medium.com/@amuino/running-elixir-tests-without-a-mix-project-a97bc05a1657


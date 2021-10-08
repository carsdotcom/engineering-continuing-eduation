defmodule CryptoPals.Set1.Challenge6 do
  alias CryptoPals.Set1.Challenge3

  @moduledoc """
  Source: 'https://cryptopals.com/sets/1/challenges/6'

  Solution code should be written here.

  To run tests, paste the following into the commandline from the project root.
  ```bash
  elixir -r cryptopals/set1/challenge6/elixir_template/challenge6_template.ex
  ```

  When submitting, change the name of this file to reflect the names of those
  that participated in the solution. (ex: `Challenge6_mary_linda_harriet.ex`)
  Then create a PR to add your file to the repo under
  `cryptopals/set1/challenge6/submitted_solutions/`.

  PROBLEM:
  Break repeating-key XOR
  It is officially on, now.

  This challenge isn't conceptually hard, but it involves actual error-prone
  coding. The other challenges in this set are there to bring you up to speed.
  This one is there to qualify you. If you can do this one, you're probably just
  fine up to Set 6.

  There's a file here: (./cryptopals/set1/challenge6/challenge_materials/6.txt).
  It's been base64'd after being encrypted with repeating-key XOR.

  Decrypt it.

  Here's how:

    1.  Let KEYSIZE be the guessed length of the key; try values from 2 to (say)
        40.

    2.  Write a function to compute the edit distance/Hamming distance between
        two strings. The Hamming distance is just the number of differing bits.
        The distance between:
            `this is a test`
        and
            `wokka wokka!!!`
        is 37. Make sure your code agrees before you proceed.

    3.  For each KEYSIZE,
        ----  option 1  -------------------  ----  options 2  ------------------
        take the first KEYSIZE worth of       (see below)
        bytes, and the second KEYSIZE worth
        of bytes,
        -----------------------------------  -----------------------------------
        and find the edit distance between them. Normalize this result by
        dividing by KEYSIZE.

    4.  The KEYSIZE with the smallest normalized edit distance is probably the
        key.
        ----  option 1  -------------------  ----  option 2  -------------------
        You could proceed perhaps with the    Or take 4 KEYSIZE blocks instead
        smallest 2-3 KEYSIZE values.          of 2 and average the distances.
        -----------------------------------  -----------------------------------

    5.  Now that you probably know the KEYSIZE: break the ciphertext into blocks
        of KEYSIZE length.

    6.  Now transpose the blocks: make a block that is the first byte of every
        block, and a block that is the second byte of every block, and so on.

    7.  Solve each block as if it was single-character XOR. You already have
        code to do this.

    8.  For each block, the single-byte XOR key that produces the best looking
        histogram is the repeating-key XOR key byte for that block. Put them
        together and you have the key.

  This code is going to turn out to be surprisingly useful later on. Breaking
  repeating-key XOR ("Vigenere") statistically is obviously an academic
  exercise, a "Crypto 101" thing. But more people "know how" to break it than
  can actually break it, and a similar technique breaks something much more
  important.

  > No, that's not a mistake.
  >
  > We get more tech support questions for this challenge than any of the other
  > ones. We promise, there aren't any blatant errors in this text. In
  > particular: the "wokka wokka!!!" edit distance really is 37.
  """

  @file_path Path.expand(__DIR__) <> "/6.txt"
  @guessed_lengths 2..40

  @doc """
  Entry fn
  """
  @spec keymaster() :: list(charlist())
  def keymaster() do
    block_of_text =
      @file_path
      |> File.read!()
      |> Base.decode64!(ignore: :whitespace)

    # 1.  Let KEYSIZE be the guessed length of the key; try values from 2 to
    #     (say) 40.
    {keysize, _score} =
      @guessed_lengths
      # 3a. For each KEYSIZE,
      |> Enum.map(fn keysize ->
        {keysize, loopy_chunks(keysize, block_of_text)}
      end)
      # 4. The KEYSIZE with the smallest normalized edit distance is probably
      #     the key.
      #     TODONT: 4a. You could proceed perhaps with the smallest 2-3 KEYSIZE
      #                 values.
      #     TODONE: 4b. Or take 4 KEYSIZE blocks instead of 2 and average the
      #                 distances.
      |> Enum.sort_by(fn {_keysize, score} -> score end, :asc)
      |> List.first()

    # 5a. Now that you probably know the KEYSIZE:
    try_keys(keysize, block_of_text)
  end

  @spec try_keys(integer(), binary()) :: list(charlist())
  defp try_keys(keysize, block_of_text) do
    # 5b. break the ciphertext into blocks of KEYSIZE length.
    chunky_text =
      block_of_text
      |> to_charlist()
      |> Enum.chunk_every(keysize)

    key =
      chunky_text
      # 6.  Now transpose the blocks: make a block that is the first byte of
      #     every block, and a block that is the second byte of every block, and
      #     so on.
      |> transpose()
      # 8.  For each block, the single-byte XOR key that produces the best
      #     looking histogram is the repeating-key XOR key byte for that block.
      #     Put them together and you have the key.
      |> Enum.reduce([], fn chunk, agg ->
        # 7.  Solve each block as if it was single-character XOR. You already
        #     have code to do this.
        [chunk |> Challenge3.re_xorcist() |> elem(0) | agg]
      end)
      |> Enum.reverse()

    chunky_text
    |> Enum.map(fn chunk ->
      key
      |> Enum.zip(chunk)
      |> Enum.reduce([], fn {key, chunk}, agg ->
        [chunk |> Bitwise.bxor(key) | agg]
      end)
      |> Enum.reverse()
    end)
  end

  @spec pad_chunks(list(charlist())) :: list(charlist())
  def pad_chunks(lists) do
    len = Enum.reduce(lists, 0, &max(length(&1), &2))

    Enum.map(lists, fn list ->
      list ++ List.duplicate(0, len - length(list))
    end)
  end

  @spec transpose(list(charlist())) :: list(charlist())
  def transpose([a | _] = list_of_lists) do
    list_of_lists
    |> pad_chunks()
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  @spec hamming_distance(String.t() | charlist(), String.t() | charlist()) :: float()
  def hamming_distance(a, b) do
    [a, b]
    |> Enum.map(&to_charlist/1)
    |> Enum.zip()
    |> Enum.reduce(0, fn {a, b}, agg ->
      a
      |> Bitwise.bxor(b)
      |> Integer.to_string(2)
      |> to_charlist()
      |> Enum.count(fn
        ?0 -> false
        ?1 -> true
      end)
      |> Kernel.+(agg)
    end)
  end

  @spec loopy_chunks(integer(), String.t()) :: float()
  defp loopy_chunks(keysize, encoded_string) do
    # TODONT: 3b. take the first KEYSIZE worth of bytes, and the second KEYSIZE
    #             worth of bytes,
    # TODONE: 4b. Or take 4 KEYSIZE blocks instead of 2
    chunks =
      encoded_string
      |> to_charlist()
      |> Enum.chunk_every(keysize)
      |> Enum.take(4)

    for {x, i} <- Enum.with_index(chunks),
        y <- Enum.slice(chunks, (i + 1)..(length(chunks) - 1)) do
      # 3c. and find the edit distance between them. Normalize this result by
      #     dividing by KEYSIZE.
      hamming_distance(x, y) / keysize
    end
    # TODONE: 4c. and average the distances.
    |> Enum.sum()
    |> Kernel./(6)
  end
end

ExUnit.start()
ExUnit.configure(exclude: :pending, trace: true)

defmodule CryptoPals.Set1.Challenge6Test do
  @moduledoc """
  Tests for Cryptopals Challenge 6.
  For a submission to be considered "complete", all tests should pass.
  """

  use ExUnit.Case
  alias CryptoPals.Set1.Challenge6

  describe("transpose/1") do
    test "given a list of lists transposes" do
      assert [
               [1, "a", :x],
               [2, "b", :y],
               [3, "c", :z]
             ] ==
               Challenge6.transpose([
                 [1, 2, 3],
                 ["a", "b", "c"],
                 [:x, :y, :z]
               ])
    end
  end

  describe "keymaster/0" do
    test "with a valid text file, returns something" do
      Challenge6.keymaster()
    end
  end

  # 2.  Write a function to compute the edit distance/Hamming distance between
  #     two strings. The Hamming distance is just the number of differing bits.
  #     The distance between:
  #       `this is a test`
  #     and
  #       `wokka wokka!!!`
  #     is 37. Make sure your code agrees before you proceed.
  describe "hamming_distance" do
    test "computes the edit distance given two strings" do
      assert 37 == Challenge6.hamming_distance("this is a test", "wokka wokka!!!")
      assert 1 == Challenge6.hamming_distance("A", "@")
    end
  end

  describe("pad_chunks/1") do
    test "does nothing if all the lists are the same length" do
      lists = [
        [1, 2, 3, 4],
        ["a", "b", "c", "d"],
        [:w, :x, :y, :z]
      ]

      assert lists == Challenge6.pad_chunks(lists)
    end

    test "pads every list with zeroes to match the length of the longest list" do
      list1 = [1]
      list2 = ["a", "b", "c", "d"]
      list3 = [:y, :z]
      list4 = [?A, ?B, ?C]

      assert [[1, 0, 0, 0], list2, [:y, :z, 0, 0], [?A, ?B, ?C, 0]] ==
               Challenge6.pad_chunks([list1, list2, list3, list4])
    end
  end
end

defmodule CryptoPals.Set1.Challenge3 do
  use Bitwise

  @moduledoc """
  # luce_jerry_joe solution
  """

  @average_word_length 4.7
  # <<32>>
  @space " "

  @spec re_xorcist(charlist()) :: {byte(), float(), String.t()}
  def re_xorcist(clist) do
    list_all_characters()
    |> Enum.map(&xor_encrypt(clist, &1))
    |> Enum.map(&score_message/1)
    |> Enum.sort_by(&elem(&1, 1), :asc)
    |> List.first()
  end

  @spec xor_encrypt(charlist(), byte()) :: {byte(), binary()}
  def xor_encrypt(clist, char) do
    bin =
      clist
      |> Enum.map(&bxor(&1, char))
      |> encode_charlist_to_binary()

    {char, bin}
  end

  @spec encode_charlist_to_binary(charlist()) :: binary()
  defp encode_charlist_to_binary(chars), do: List.to_string(chars)

  @spec list_all_characters() :: [byte()]
  defp list_all_characters, do: 0..255

  @spec score_message({byte(), binary()}) :: {byte(), float(), binary()}
  defp score_message({char, message}), do: {char, score_message(message), message}

  @spec score_message(binary()) :: float()
  defp score_message(message) do
    weighted_scores = [
      {2, score_by_printability(message)},
      {1, score_by_word_length(message)}
    ]

    # TODO: score by more criteria and aggregate a message's scores

    {weights, _scores} = Enum.unzip(weighted_scores)

    agg_score =
      weighted_scores
      |> Enum.map(fn {w, s} -> w * s end)
      |> Enum.sum()
      |> Kernel./(Enum.sum(weights))

    agg_score
  end

  @spec score_by_printability(binary()) :: float()
  defp score_by_printability(message) do
    case List.ascii_printable?(String.to_charlist(message)) do
      true -> 0.0
      false -> 1.0
    end
  end

  @spec score_by_word_length(binary()) :: float()
  defp score_by_word_length(message) do
    # HT: @jwharrow for the heuristic!

    word_list = String.split(message, @space)

    total_num_chars = String.length(message)
    sum_word_length = total_num_chars - length(word_list) + 1
    avg_word_length = sum_word_length / length(word_list)

    delta = abs(avg_word_length / @average_word_length - 1)
    normal = total_num_chars / @average_word_length - 1

    delta / normal
  end
end

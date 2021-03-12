defmodule ElixirSessions.Parser do
  @moduledoc false
  # Parses an input string to session types (as Elixir data).
  require Logger
  require ST

  @typedoc false
  @type session_type :: ST.session_type()
  @type session_type_incl_label :: ST.session_type_incl_label()

  # Parses a session type from a string to an Elixir data structure.
  @spec parse_incl_label(bitstring() | charlist()) :: session_type_incl_label()
  def parse_incl_label(string) when is_bitstring(string) do
    string
    |> String.to_charlist()
    |> parse_incl_label()
  end

  def parse_incl_label(string) do
    with {:ok, tokens, _} <- lexer(string) do
      if tokens == [] do
        # Empty input
        {:nolabel, %ST.Terminate{}}
      else
        {:ok, {label, session_type}} = :parse.parse(tokens)
        # YeccRet = {ok, Parserfile} | {ok, Parserfile, Warnings} | error | {error, Errors, Warnings}

        session_type_s = ST.convert_to_structs(session_type)

        # todo convert branches with one option to receive statements
        # and choices with one choice to send

        ST.validate!(session_type_s)
        {label, session_type_s}
      end
    else
      err ->
        # todo: cuter error message needed
        _ = Logger.error(err)
        []
    end
  end

  @spec parse(bitstring() | charlist()) :: session_type()
  def parse(s) do
    {_label, st} = parse_incl_label(s)
    st
  end

  defp lexer(string) do
    # IO.inspect tokens
    :lexer.string(string)
    |> IO.inspect
  end

  @doc false
  # recompile && ElixirSessions.Parser.run
  def run() do
    _leex_res = :leex.file('src/lexer.xrl')

    source = "jhasd = "
    # source = "S_1 = &{?Neg(number, pid).?Hello(number)}"
    # source = "!Hello(Integer).+{?neg(number, pid).?Num(Number), !neg(number, pid).?Num(Number)}"
    # source = "rec X.(&{?Ping().!Pong().X, ?Quit().end})"
    # source = "?Hello().!ABc(number).!ABc(number, number).&{?Hello().?Hello2(), ?Hello(number)}"
    # source = "?M220(msg: String).+{ !Helo(hostname: String).?M250(msg: String). rec X.(+{ !MailFrom(addr: String). ?M250(msg: String) . rec Y.(+{ !RcptTo(addr: String).?M250(msg: String).Y, !Data().?M354(msg: String).!Content(txt: String).?M250(msg: String).X, !Quit().?M221(msg: String) }), !Quit().?M221(msg: String)}), !Quit().?M221(msg: String) }"

    parse_incl_label(source)
    |> ST.st_to_string()
  end
end

defmodule Helpers do
  @moduledoc false
  def extract_token({_token, _line, value}), do: value
  def to_atom(':' ++ atom), do: List.to_atom(atom)
end

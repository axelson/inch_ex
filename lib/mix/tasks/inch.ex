# Original code adapted from ExDoc

defmodule Mix.Tasks.Inch do
  use Mix.Task

  @shortdoc "Report documentation for the project"
  @recursive true

  @doc false
  def run(args, config \\ Mix.Project.config, generator \\ &InchEx.generate_docs/3, reporter \\ InchEx.Reporter.Local) do
    Mix.Task.run "compile"

    { cli_opts, args, _ } = OptionParser.parse(args, aliases: [o: :output], switches: [output: :string])

    if args != [] do
      raise Mix.Error, message: "Extraneous arguments on the command line"
    end

    project = (config[:name] || config[:app]) |> to_string
    version = config[:version] || "dev"
    options = Keyword.merge(get_docs_opts(config), cli_opts)

    if source_url = config[:source_url] do
      options = Keyword.put(options, :source_url, source_url)
    end

    cond do
      nil?(options[:main]) ->
        # Try generating main module's name from the app name
        options = Keyword.put(options, :main, (config[:app] |> Atom.to_string |> Mix.Utils.camelize))

      is_atom(options[:main]) ->
        options = Keyword.update!(options, :main, &inspect/1)

      is_binary(options[:main]) ->
        options
    end

    options = Keyword.put_new(options, :source_beam, Mix.Project.compile_path)
    options = Keyword.put_new(options, :retriever, InchEx.Docs.Retriever)
    options = Keyword.put_new(options, :formatter, InchEx.Docs.Formatter)

    generator.(project, version, options)
      |> reporter.run
  end

  defp get_docs_opts(config) do
    docs = config[:docs]
    cond do
      is_function(docs, 0) -> docs.()
      nil?(docs) -> []
      true -> docs
    end
  end
end

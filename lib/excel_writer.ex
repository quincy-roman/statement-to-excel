defmodule ExcelWriter do
  alias Elixlsx.{Workbook, Sheet}

  @header [
    "Date",
    "Description",
    "Amount"
  ]

  def write_tuples_to_xlsx(rows, filename) do
    %Sheet{name: "Statement", rows: [@header] ++ rows, pane_freeze: {1, 0}}
    |> (&%Workbook{sheets: [&1]}).()
    |> Elixlsx.write_to("./outputs/#{filename}.xlsx")

    {rows, :ok}
  end
end

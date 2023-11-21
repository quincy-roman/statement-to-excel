defmodule StatementToExcel do
  @moduledoc """
  Documentation for `StatementToExcel`.
  """

  @doc """
  Converts a PDF bank statement to an XLSX document for better
    data management.

  ## Examples

      iex> StatementToExcel.statement_to_excel("/path/to/statement.pdf")
      :ok

  """
  def statement_to_excel(pdf_path) do
    # TODO: Add validation to ensure path is a PDF
    {pdf_as_txt, exit_status} =
      System.cmd("pdftotext", ["-raw", pdf_path, "-"])

    extract_data_from_pdf(pdf_as_txt, exit_status)
    |> ExcelWriter.write_tuples_to_xlsx(Path.basename(pdf_path, ".pdf"))
  end

  defp extract_data_from_pdf(txt, 0) do
    txt
    |> String.split("\n")
    |> Enum.join(" ")
    |> extract_statement_data()
    |> Stream.map(&hd(&1))
    |> Stream.map(&scan_statement_text/1)
    |> Stream.reject(&is_nil/1)
    |> Stream.chunk_by(&is_atom/1)
    |> Enum.map_reduce(nil, &assign_category/2)
    |> elem(0)
    |> Enum.reject(&is_nil/1)
    |> Enum.flat_map(&Function.identity/1)
  end

  defp extract_data_from_pdf(_, _), do: raise("Cannot process file")

  defp extract_statement_data(txt) do
    Regex.scan(~r/(Deposits|Payments)|(\d{2}\/\d{2}\s.*\.\d{2})/U, txt, capture: :all)
  end

  defp scan_statement_text(line) do
    # TD Format, look into including others, use a atom to differentiate
    regexline =
      Regex.run(
        ~r/(Deposits|Payments)|(\d{2}\/\d{2})(\s.*[A-Za-z\s])((\d,)?\d{1,3}\.\d{2})/,
        line
      )

    case regexline do
      [_, _, date, description, amount | _] ->
        formatted_amount = amount |> String.replace(",", "") |> String.to_float()
        [date, String.trim(description), formatted_amount]

      [_, "Payments"] ->
        :payments

      [_, "Deposits"] ->
        :deposits

      _ ->
        nil
    end
  end

  defp assign_category(list, category) do
    if is_atom(hd(list)) do
      {nil, List.last(list)}
    else
      {list
       |> Enum.map(fn [date, desc, amount] ->
         [
           atom_to_string(category),
           date,
           desc,
           if(category == :payments,
             do: amount * -1,
             else: amount
           )
         ]
       end), category}
    end
  end

  defp atom_to_string(atom) when is_atom(atom), do: Atom.to_string(atom) |> String.capitalize()
end

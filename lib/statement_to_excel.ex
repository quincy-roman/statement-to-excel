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

    {extract_data_from_pdf(pdf_as_txt, exit_status), :ok}
  end

  defp extract_data_from_pdf(txt, 0) do
    txt
    |> String.split("\n")
    |> Enum.join(" ")
    |> extract_statement_data()
    |> Stream.map(fn sublist -> hd(sublist) end)
    |> Stream.map(&scan_statement_text/1)
    |> Enum.reject(&is_nil/1)
  end

  defp extract_data_from_pdf(_, _), do: raise("Cannot process file")

  defp extract_statement_data(txt) do
    # TODO: make sure to extract the categories as well (deposits vs payments)
    Regex.scan(~r/(\d{2}\/\d{2}\s.*\.\d{2})/U, txt, capture: :all)
  end

  defp scan_statement_text(line) do
    # TD Format, look into including others, use a atom to differentiate
    regexline =
      Regex.run(
        ~r/(\d{2}\/\d{2})(\s.*[A-Za-z\s])((\d,)?\d{1,3}\.\d{2})/,
        line
      )

    case regexline do
      [_, date, description, amount | _] ->
        {date, String.trim(description), amount}

      ["Electronic Payments", _] ->
        :payments

      _ ->
        nil
    end
  end
end

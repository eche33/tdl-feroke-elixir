defmodule EpidemicSimulator.PopulationGraphPlotter do
  @output_folder "./plots/"

  def generate_graph_plot_for(census_data, simulation_step) do
    dataset = Contex.Dataset.new(census_data, ["x", "y", "person", "health_status"])
    categories = dataset |> Contex.Dataset.unique_values("health_status")
    colours = Enum.map(categories, Contex.CategoryColourScale.domain_to_range_fn(color_palette()))

    statistics = generate_statistics(census_data)

    options = [
      mapping: %{x_col: "x", y_cols: ["y"], fill_col: "health_status"},
      data_labels: true,
      orientation: :vertical,
      colour_palette: colours,
      legend_setting: :legend_right,
      title: "Virus propagation",
      x_label: "#{Enum.join(statistics, ", ")}"
    ]

    plot = Contex.Plot.new(dataset, Contex.PointPlot, 600, 600, options)
    {:safe, plot_as_svg_image} = Contex.Plot.to_svg(plot)

    create_folder(@output_folder)

    save_plot_image(plot_as_svg_image, simulation_step)
  end

  defp generate_statistics(data) do
    statistics =
      Enum.map(all_possible_health_statuses(), fn counting_health_status ->
        amount_of_people_with_health_status =
          Enum.count(data, fn {_, _, _, health_status} ->
            health_status == counting_health_status
          end)

        "#{counting_health_status}: #{amount_of_people_with_health_status}"
      end)

    statistics
  end

  defp all_possible_health_statuses do
    ["healthy", "incubating", "sick", "immune", "dead"]
  end

  defp color_palette do
    Contex.CategoryColourScale.new(all_possible_health_statuses(), [
      "43db8c",
      "286268",
      "a11730",
      "ffcc9c",
      "120a1f"
    ])
  end

  defp save_plot_image(plot_image, simulation_step) do
    filename = "population_step=#{simulation_step}.svg"
    {:ok, file} = File.open("#{@output_folder}#{filename}", [:write])
    IO.binwrite(file, plot_image)
    File.close(file)
  end

  defp create_folder(folder) do
    if not File.exists?(folder) do
      File.mkdir(folder)
    end
  end
end
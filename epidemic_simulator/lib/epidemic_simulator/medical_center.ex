defmodule EpidemicSimulator.MedicalCenter do
  use GenServer

  @me __MODULE__

  def plot() do
    # Creo la carpeta, si existe no hago nada
    folder = "./outs/"
    if not File.exists?(folder) do
      File.mkdir(folder)
    end

    # Genero la data
    actors = ["Child", "Adult"]
    status = ["healthy", "incubating", "sick", "inmune", "dead"]

    rand_uniform = fn a, b ->
      :rand.uniform() * (b-a) + a
    end

    data = 1..300 |> Enum.map(fn _ -> {rand_uniform.(0,5), rand_uniform.(0,5), Enum.take_random(actors, 1)|>hd, Enum.take_random(status,1)|>hd} end)

    # Cuento los estados de la poblacion
    status_count = fn st, d ->
      c = Enum.count(d, fn {x,y,a,s} -> s == st end)
      "#{st}: #{c}"
    end

    report = status |> Enum.map(fn st -> status_count.(st, data) end)

    # Creo mi paleta de colores para colorear Adult y Child
    colour_scale = Contex.CategoryColourScale.new(status, ["43db8c", "cbd42b", "a11730", "286268", "120a1f"])

    # Creo mi dataset y lo coloreo según mi paleta
    ds = Contex.Dataset.new(data, ["x", "y", "person", "health_status"])
    categories = ds |> Contex.Dataset.unique_values("health_status")
    colours = Enum.map(categories, Contex.CategoryColourScale.domain_to_range_fn(colour_scale))

    # Genero el gráfico
    options = [
      mapping: %{x_col: "x", y_cols: ["y"], fill_col: "health_status"},
      data_labels: true,
      orientation: :vertical,
      colour_palette: colours,
      legend_setting: :legend_right,
      title: "Virus propagation",
      x_label: "#{Enum.join(report, ", ")}"
    ]
    plot = Contex.Plot.new(ds, Contex.PointPlot, 600,600, options)
    {:safe, svg} = Contex.Plot.to_svg(plot)

    # Guardo la imagen
    filename = "population_test.svg"
    {:ok, file} = File.open("#{folder}#{filename}", [:write])
    IO.binwrite(file, svg)
    File.close(file)

  end

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:start, time, name}, state) do
    :timer.sleep(:timer.seconds(time))

    GenServer.cast(name, :ring)
    {:noreply, state}
  end

end

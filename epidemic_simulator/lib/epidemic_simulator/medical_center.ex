defmodule EpidemicSimulator.MedicalCenter do
  use GenServer

  @me __MODULE__
  def test() do
    GenServer.cast(MedicalCenter, {:census, :Adult1, {1,1}, :healthy})
    GenServer.cast(MedicalCenter, {:census, :Adult2, {2,2}, :incubating})
    GenServer.cast(MedicalCenter, {:census, :Adult3, {3,3}, :sick})
    GenServer.cast(MedicalCenter, {:census, :Adult4, {4,4}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult5, {5,5}, :inmune})
    GenServer.cast(MedicalCenter, :ring)

    GenServer.cast(MedicalCenter, {:census, :Adult1, {1,1}, :incubating})
    GenServer.cast(MedicalCenter, {:census, :Adult2, {2,2}, :incubating})
    GenServer.cast(MedicalCenter, {:census, :Adult3, {3,3}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult4, {4,4}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult5, {5,5}, :inmune})
    GenServer.cast(MedicalCenter, :ring)

    GenServer.cast(MedicalCenter, {:census, :Adult1, {1,1}, :incubating})
    GenServer.cast(MedicalCenter, {:census, :Adult2, {2,2}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult3, {3,3}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult4, {4,4}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult5, {5,5}, :inmune})
    GenServer.cast(MedicalCenter, :ring)

    GenServer.cast(MedicalCenter, {:census, :Adult1, {1,1}, :inmune})
    GenServer.cast(MedicalCenter, {:census, :Adult2, {2,2}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult3, {3,3}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult4, {4,4}, :dead})
    GenServer.cast(MedicalCenter, {:census, :Adult5, {5,5}, :inmune})
    GenServer.cast(MedicalCenter, :ring)

  end

  def plot(state) do
    data = state.citizens |> Enum.map(fn {key, {x,y,health_status}} -> {x,y,key,"#{health_status}"}  end)
    i = state.step

    # Creo la carpeta, si existe no hago nada
    folder = "./outs/"
    if not File.exists?(folder) do
      File.mkdir(folder)
    end

    # Cuento los estados de la poblacion
    status_count = fn st, d ->
      c = Enum.count(d, fn {_,_,_,s} -> s == st end)
      "#{st}: #{c}"
    end

    status = ["healthy", "incubating", "sick", "inmune", "dead"]
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
    filename = "population_step=#{i}.svg"
    {:ok, file} = File.open("#{folder}#{filename}", [:write])
    IO.binwrite(file, svg)
    File.close(file)

  end

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  @impl true
  def init(:ok) do
    initial_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: %{},
      step: 0
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:census, name, position, health_status}, state) do
    IO.puts("census")
    {x, y} = position

    updated_citizens = Map.put(state.citizens, name, {x, y, health_status})

    IO.puts(inspect(updated_citizens))
    new_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: updated_citizens,
      step: state.step
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:ring, state) do
    IO.puts("ring")
    #Agent.stop(String.to_atom("#{state.name}_timer"))

    plot(state)

    #Agent.start(String.to_atom("#{state.name}_timer"))
    new_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: state.citizens,
      step: state.step + 1
    }

    {:noreply, new_state}
  end

end

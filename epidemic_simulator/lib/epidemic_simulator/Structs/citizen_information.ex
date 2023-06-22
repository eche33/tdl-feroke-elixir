defmodule EpidemicSimulator.Structs.CitizenInformation do
  defstruct [
    :name,
    :pos,
    :neighbours,
    :health_status,
    :contagion_resistance,
    :comorbidities,
    :simulation_running,
    :virus
  ]
end

defmodule EpidemicSimulator.Structs.CitizenInformation do
  defstruct [
    :name,
    :neighbours,
    :health_status,
    :contagion_resistance,
    :comorbidities,
    :simulation_running,
    :virus
  ]
end

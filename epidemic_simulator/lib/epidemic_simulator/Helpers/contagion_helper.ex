defmodule EpidemicSimulator.Helpers.ContagionHelper do

  def get_sick?(citizen_information) do
    contagion_resistance = citizen_information.contagion_resistance

    contagion_resistance < :rand.uniform()
  end

end

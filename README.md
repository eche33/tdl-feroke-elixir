# TDL - Feroke - Elixir

[![Elixir CI](https://github.com/eche33/tdl-feroke-elixir/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/eche33/tdl-feroke-elixir/actions/workflows/elixir.yml)

## Introducción
Trabajo Práctico final de la materia Teoría del Lenguaje de la Facultad de Ingeniería de la Universidad de Buenos Aires.

## Video de la presentación final
[Video](https://youtu.be/b4Vjk1mRsfg)
## Integrantes
|   Nombre| Apellido   | Padrón  |
|---|---|---|
| Felipe  | Marelli  |  106521 |
| Kevin  | Grattan Plunkett  | 100487  |
| Rodrigo  | Etchegaray Campisi  | 96856  |

## Requisitos
- Erlang VM y Elixir

Para OS Windows se puede instalar de la [página oficial](https://elixir-lang.org/install.html#windows).

Para Linux recomendamos usar asdf, [esta guía](https://apollin.com/how-to-install-elixir-on-ubuntu-22-using-asdf/) explica detalladamente cómo usarlo.

## Correr el código
- ```cd epidemic_simulator```
- ```mix deps.get```
- ```iex -S mix```
- ```EpidemicSimulator.create_population```
- ```EpidemicSimulator.create_virus```
- ```EpidemicSimulator.simulate_virus(5)```
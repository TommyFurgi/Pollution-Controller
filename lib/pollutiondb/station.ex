defmodule Pollutiondb.Station do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Pollutiondb.Repo

  schema "stations" do
    field :name, :string
    field :lon, :float
    field :lat, :float

    has_many :readings, Pollutiondb.Reading
  end

  defp validate(station, changesmap) do
    station
    |> Ecto.Changeset.cast(changesmap, [:name, :lon, :lat])
    |> Ecto.Changeset.validate_required([:name, :lon, :lat])
    |> Ecto.Changeset.validate_number(
         :lon, greater_than: -180.0, less_than: 180)
    |> Ecto.Changeset.validate_number(
         :lat, greater_than: -90.0, less_than: 90.0)
  end

  def add(station) do
    station |> Pollutiondb.Repo.insert()
  end

  def changeset(station, params \\ %{}) do
    station
    |> cast(params, [:name, :lon, :lat])
    |> validate_required([:name, :lon, :lat])
    |> validate_number(:lon, greater_than: -180.0, less_than: 180.0)
    |> validate_number(:lat, greater_than: -90.0, less_than: 90.0)
  end

  def add(name, lon, lat) do
    changeset(%Pollutiondb.Station{}, %{name: name, lon: lon, lat: lat})
    |> Repo.insert()
  end


  def get_by_id(id) do
    Pollutiondb.Repo.get(Pollutiondb.Station, id)
  end

  def get_all() do
    Pollutiondb.Repo.all(Pollutiondb.Station)
    |> Pollutiondb.Repo.preload(:readings)
  end

  def remove(station) do
    Pollutiondb.Repo.delete(station)
  end

  def find_by_name(name) do
    query =
      from(s in Pollutiondb.Station,
        where: like(s.name, ^"%#{name}%"),
        preload: [:readings]
      )

    Pollutiondb.Repo.all(query)
  end


  def find_by_location(lon, lat) do
    Ecto.Query.from(s in Pollutiondb.Station,
      where: s.lon == ^lon,
      where: s.lat == ^lat)
    |> Pollutiondb.Repo.all
  end

  def find_by_location_range(lon_min, lon_max, lat_min, lat_max) do
    Ecto.Query.from(
      s in Pollutiondb.Station,
      where: ^lon_min <= s.lon and s.lon <= ^lon_max,
      where: ^lat_min <= s.lat and s.lat <= ^lat_max
    )
    |> Pollutiondb.Repo.all
  end

  def update_name(station, new_name) do
    station
    |> validate(%{name: new_name})
    |> Pollutiondb.Repo.update
  end

  def delete_by_name(name) do
    station =
      Pollutiondb.Repo.get_by(Pollutiondb.Station, name: name)

    case station do
      nil ->
        {:error, "Station not found"}

      _ ->
        Pollutiondb.Repo.delete(station)
        {:ok, "Station '#{name}' deleted successfully"}
    end
  end


end




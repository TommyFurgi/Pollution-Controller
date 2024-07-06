defmodule Pollutiondb.Reading do
  use Ecto.Schema
  import Ecto.Query
  alias Pollutiondb.Repo
  alias Pollutiondb.Station

  schema "readings" do
    field :datetime, :utc_datetime
    field :type, :string
    field :value, :float

    belongs_to :station, Pollutiondb.Station
  end

  def get_all() do
    Pollutiondb.Repo.all(Pollutiondb.Reading)
    |> Pollutiondb.Repo.preload(:station)
  end

  def changeset(reading, params \\ %{}) do
    reading
    |> Ecto.Changeset.cast(params, [:datetime, :type, :value, :station_id])
    |> Ecto.Changeset.validate_required([:datetime, :type, :value, :station_id])
  end

  def add(reading) do
    Pollutiondb.Repo.insert(reading)
  end

  def add_now(station, type, value) do
    %Pollutiondb.Reading{}
    |> changeset(%{
      datetime: DateTime.utc_now |> DateTime.truncate(:second) |> DateTime.to_iso8601,
      type: type,
      value: value,
      station_id: station.id
    })
    |> Pollutiondb.Repo.insert()
  end


  def find_by_date(date) do
    minDateTime = DateTime.new!(date, ~T[00:00:00])
    maxDateTime = DateTime.add(minDateTime, 24*60*60, :second)
    Ecto.Query.from(
      r in Pollutiondb.Reading,
      where: ^minDateTime <= r.datetime,
      where: r.datetime <= ^maxDateTime
    )
    |> Pollutiondb.Repo.all
  end

  def find_by_id(station_id) do
    Ecto.Query.from(
      r in Pollutiondb.Reading,
      where: r.station_id == ^station_id,
      preload: [:station]
    )
    |> Pollutiondb.Repo.all
  end

  def get_20_latest_readings do
    Ecto.Query.from(r in Pollutiondb.Reading, limit: 20, order_by: [desc: r.datetime])
    |> Pollutiondb.Repo.all()
    |> Pollutiondb.Repo.preload(:station)
  end

  def get_20_latest_readings_with_date(date \\ Date.utc_today()) do
    min_datetime = DateTime.new!(date, ~T[00:00:00])
    max_datetime = DateTime.add(min_datetime, 24*60*60, :second)

    query =
      from(r in Pollutiondb.Reading,
        where: r.datetime >= ^min_datetime and r.datetime <= ^max_datetime,
        order_by: [desc: r.datetime],
        limit: 20)
      |> Repo.all()
      |> Repo.preload(:station)

    query
  end


end

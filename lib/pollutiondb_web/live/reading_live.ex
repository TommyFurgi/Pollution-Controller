defmodule PollutiondbWeb.ReadingLive do
  use PollutiondbWeb, :live_view
  alias Pollutiondb.Station
  alias Pollutiondb.Reading

  def mount(_params, _session, socket) do
    stations = Station.get_all()
    socket =
      assign(socket,
        readings: Reading.get_20_latest_readings(),
        date: "",
        type: "",
        value: "",
        station_id: 0,
        stations: stations
      )
    {:ok, socket}
  end

  defp to_date(date) do
    case Date.from_iso8601(date) do
      {:ok, date} -> date
      :error -> Date.utc_today()
    end
  end

  defp to_float(value, default \\ 0.0) do
    case Float.parse(value) do
      {float_value, _rest} -> float_value
      :error -> default
    end
  end

  defp to_int(value, default \\ 1) do
    case Integer.parse(value) do
      {int_value, _rest} -> int_value
      :error -> default
    end
  end

  def handle_event("get_by_date", %{"date" => date}, socket) do
    date = to_date(date)
    readings = Reading.get_20_latest_readings_with_date(date)
    socket = assign(socket, readings: readings, date: date)
    {:noreply, socket}
  end

  def handle_event("get_by_station", %{"station_id" => station_id}, socket) do
    readings = Reading.find_by_id(to_int(station_id))
    socket = assign(socket, readings: readings, station_id: station_id)
    {:noreply, socket}
  end

  def handle_event("add_reading", %{"type" => type, "value" => value, "station_id" => station_id}, socket) do
    station_id = to_int(station_id)
    station = %Station{id: station_id}
    case Reading.add_now(station, type, to_float(value)) do
      {:ok, _reading} ->
        readings = Reading.get_20_latest_readings()
        {:noreply, assign(socket, readings: readings, type: "", value: "", station_id: station_id)}
      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="forms">
        <div class="form-section">
          <h2>Latest readings</h2>
          <form phx-submit="get_by_date" class="create-form">
            <label>Date: <input type="date" name="date" value={@date} /></label>
            <input type="submit" value="Get readings" />
          </form>
        </div>
        <div class="form-section">
          <h2>Readings from station</h2>
          <form phx-change="get_by_station" class="create-form">
            <label>Station:
              <select name="station_id">
                <%= for station <- @stations do %>
                  <option label={station.name} value={station.id} selected={station.id == @station_id}/>
                <% end %>
              </select>
            </label><br/>
          </form>
        </div>
        <div class="form-section">
          <h2>Add reading</h2>
          <form phx-submit="add_reading" class="create-form">
            <label>Type: <input type="text" name="type" value={@type} /></label><br/>
            <label>Value: <input type="number" name="value" step="0.01" value={@value} /></label><br/>
            <label>Station:
              <select name="station_id">
                <%= for station <- @stations do %>
                  <option label={station.name} value={station.id} selected={station.id == @station_id}/>
                <% end %>
              </select>
            </label><br/>
            <input type="submit" value="Add reading" />
          </form>
        </div>
      </div>
      <div class="results">
        <h2>Readings</h2>
        <table class="results-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Type</th>
              <th>Value</th>
              <th>Station</th>
            </tr>
          </thead>
          <tbody>
            <%= for reading <- @readings do %>
              <tr>
                <td><%= reading.datetime |> DateTime.to_string() %></td>
                <td><%= reading.type %></td>
                <td><%= reading.value %></td>
                <td><%= reading.station.name %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end

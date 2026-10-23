import CoreLocation
import Foundation
import Observation

struct WeatherReport: Codable, Equatable {
    var place: String
    var temperature: Double
    var feelsLike: Double
    var code: Int
    var high: Double
    var low: Double
    var rainChance: Int
    var sunrise: Date?
    var sunset: Date?
    var fahrenheit: Bool
    var fetched: Date

    var unit: String { fahrenheit ? "°F" : "°C" }

    var summary: String { WeatherReport.describe(code) }

    var symbol: String {
        switch code {
        case 0: "sun.max"
        case 1, 2: "cloud.sun"
        case 3: "cloud"
        case 45, 48: "cloud.fog"
        case 51...57: "cloud.drizzle"
        case 61...67, 80...82: "cloud.rain"
        case 71...77, 85, 86: "cloud.snow"
        case 95...99: "cloud.bolt.rain"
        default: "thermometer.medium"
        }
    }

    static func describe(_ code: Int) -> String {
        switch code {
        case 0: "Clear"
        case 1: "Mostly clear"
        case 2: "Partly cloudy"
        case 3: "Overcast"
        case 45, 48: "Foggy"
        case 51, 53, 55: "Drizzle"
        case 56, 57: "Freezing drizzle"
        case 61: "Light rain"
        case 63: "Rain"
        case 65: "Heavy rain"
        case 66, 67: "Freezing rain"
        case 71, 73, 75, 77: "Snow"
        case 80, 81, 82: "Showers"
        case 85, 86: "Snow showers"
        case 95: "Thunderstorms"
        case 96, 99: "Storms with hail"
        default: "—"
        }
    }

    /// A short nudge based on the forecast.
    var advice: String {
        if rainChance >= 60 { return "Take an umbrella." }
        if (71...86).contains(code) { return "Bundle up, it's snowing." }
        let hiC = fahrenheit ? (high - 32) * 5 / 9 : high
        let loC = fahrenheit ? (low - 32) * 5 / 9 : low
        if hiC >= 30 { return "Hot one. Drink extra water." }
        if loC <= 2 { return "Cold out. Grab a jacket." }
        if code == 0 || code == 1 { return "Good day to get outside." }
        return "Nothing wild out there."
    }
}

/// Open-Meteo needs no key and no entitlement, so it works in a sideloaded app.
@MainActor
@Observable
final class WeatherModel: NSObject, CLLocationManagerDelegate {
    var report: WeatherReport?
    var status: Status = .idle

    enum Status: Equatable { case idle, loading, denied, failed }

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private let cacheKey = "weatherCache"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(WeatherReport.self, from: data) {
            report = cached
        }
    }

    var useFahrenheit: Bool {
        if let stored = UserDefaults.standard.object(forKey: "fahrenheit") as? Bool { return stored }
        return Locale.current.measurementSystem == .us
    }

    func refresh(force: Bool = false) {
        if !force, let r = report, Date.now.timeIntervalSince(r.fetched) < 20 * 60, r.fahrenheit == useFahrenheit { return }
        if UserDefaults.standard.bool(forKey: "demoData") {
            Task { await load(CLLocation(latitude: 40.7128, longitude: -74.0060), place: "New York") }
            return
        }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            status = .denied
        default:
            status = .loading
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.status = .loading
                manager.requestLocation()
            case .denied, .restricted:
                self.status = .denied
            default: break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            let place = await self.placeName(for: loc)
            await self.load(loc, place: place)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if self.report == nil { self.status = .failed }
        }
    }

    private func placeName(for loc: CLLocation) async -> String {
        let marks = try? await CLGeocoder().reverseGeocodeLocation(loc)
        return marks?.first?.locality ?? marks?.first?.name ?? "Here"
    }

    private func load(_ loc: CLLocation, place: String) async {
        status = .loading
        let f = useFahrenheit
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(format: "%.3f", loc.coordinate.latitude)),
            .init(name: "longitude", value: String(format: "%.3f", loc.coordinate.longitude)),
            .init(name: "current", value: "temperature_2m,apparent_temperature,weather_code"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "1"),
            .init(name: "timeformat", value: "unixtime"),
            .init(name: "temperature_unit", value: f ? "fahrenheit" : "celsius"),
        ]
        do {
            let (data, _) = try await URLSession.shared.data(from: comps.url!)
            let raw = try JSONDecoder().decode(OpenMeteo.self, from: data)
            let r = WeatherReport(
                place: place,
                temperature: raw.current.temperature_2m,
                feelsLike: raw.current.apparent_temperature,
                code: raw.current.weather_code,
                high: raw.daily.temperature_2m_max.first ?? raw.current.temperature_2m,
                low: raw.daily.temperature_2m_min.first ?? raw.current.temperature_2m,
                rainChance: raw.daily.precipitation_probability_max?.first.flatMap { $0 } ?? 0,
                sunrise: raw.daily.sunrise.first.map { Date(timeIntervalSince1970: $0) },
                sunset: raw.daily.sunset.first.map { Date(timeIntervalSince1970: $0) },
                fahrenheit: f,
                fetched: .now
            )
            report = r
            status = .idle
            if let data = try? JSONEncoder().encode(r) {
                UserDefaults.standard.set(data, forKey: cacheKey)
            }
        } catch {
            status = report == nil ? .failed : .idle
        }
    }
}

private struct OpenMeteo: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let weather_code: Int
    }

    struct Daily: Decodable {
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let sunrise: [Double]
        let sunset: [Double]
        let precipitation_probability_max: [Int?]?
    }

    let current: Current
    let daily: Daily
}

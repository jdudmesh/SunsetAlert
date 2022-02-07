//
//  ContentView.swift
//  MenuBarPopover
//
//  Created by Zafer Arıcan on 8.07.2020.
//  Modified by John Dudmesh 7/2/2022
//


import SwiftUI
import MapKit

struct SunsetTimes: Decodable {
    let sunrise: Date
    let sunset: Date
    let solarNoon: Date
    let dayLength: Int
    let civilTwilightBegin: Date
    let civilTwilightEnd: Date
    let nauticalTwilightBegin: Date
    let nauticalTwilightEnd: Date
    let astronomicalTwilightBegin: Date
    let astronomicalTwilightEnd: Date
}

struct SunsetTimesResult: Decodable {
    let results: SunsetTimes
    let status: String
}

class SunsetData: ObservableObject {
    @Published var time: Date?
    @Published var text: String?
}

struct ContentView: View {
    @State var latitude: String
    @State var longitude: String
    @State var locationText: String
    
    // this gets changed outside the view
    @ObservedObject var nextSunset: SunsetData = SunsetData()
    
    var timer: Timer?
        
    var body: some View {
        VStack(alignment: .leading){
            Text("Sunset Alert").font(.largeTitle).frame(alignment: .topLeading).padding()
            HStack(alignment: .top) {
                Image("location_pin").resizable(resizingMode: .stretch).frame(width: 32.0, height: 32.0)
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        TextField("Enter latitude...", text: $latitude)
                        TextField("Enter longitude...", text: $longitude)
                        Button("Save", action: {
                            
                            let defaults = UserDefaults.standard
                            defaults.set(latitude, forKey: "latitude")
                            defaults.set(longitude, forKey: "longitude")

                            let coder = CLGeocoder()
                            let lat = Double(latitude)
                            let lon = Double(longitude)
                            if !(lat == nil || lon == nil) {
                                let loc = CLLocation(latitude:lat!, longitude: lon!)
                                coder.reverseGeocodeLocation(loc, completionHandler:  { (placemarks, err) in
                                    let locality = placemarks?.first?.locality ?? ""
                                    let country = placemarks?.first?.country ?? ""
                                    let location = "\(locality), \(country)"
                                    defaults.set(location, forKey: "location")
                                    locationText = location
                                })
                                fetchSunsetTime()
                            }
                            
                        })
                    }
                    Text(locationText)
                        .font(.title)
                        .multilineTextAlignment(.leading)
                }
            }
            
            HStack {
                Image("sunrise_color")
                    .resizable(resizingMode: .stretch)
                    .frame(width: 100.0, height: 100.0)
                Text(nextSunset.text ?? "")
                    .font(.title)
            }
            Button("Quit", action: {
                NSApplication.shared.terminate(nil)
            })
        }
        .padding(20.0)
        .frame(width: 480.0)        
    }
    
    init() {
        let defaults = UserDefaults.standard
        _latitude = State(initialValue: defaults.string(forKey: "latitude") ?? "")
        _longitude = State(initialValue: defaults.string(forKey: "longitude") ?? "")
        _locationText = State(initialValue: defaults.string(forKey: "location") ?? "")
    }
        
    func fetchSunsetTime(isTomorrow: Bool = false) {
                
        let defaults = UserDefaults.standard
        
        // do a numeric conversion on the lat/lon. Not really necessary but useful typecheck
        let lat = Double(defaults.string(forKey: "latitude") ?? "")
        let lon = Double(defaults.string(forKey: "longitude") ?? "")
        if !(lat == nil || lon == nil) {
            
            // this is the API to call, returns a simple JSON objecy
            var urlString = "https://api.sunrise-sunset.org/json?lat=\(lat!)&lng=\(lon!)&formatted=0"
            // if already sunset already passed for today then get tomorrow's time
            if isTomorrow {
                urlString += "&date=+1day"
            }
            
            // do the call
            let url = URL(string: urlString)!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if error != nil {
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        return
                    }
                }
                if let data = data {
                    do {
                        // decode the result
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let response = try decoder.decode(SunsetTimesResult.self, from: data)
                        // process the result from the API call
                        if response.status == "OK" {
                                                        
                            if response.results.sunset.timeIntervalSinceNow < 0 {
                                // if the sunset is in the past then recurs to get tomorrow's value
                                fetchSunsetTime(isTomorrow: true)
                                return
                            }
                            
                            DispatchQueue.main.async {
                                nextSunset.time = response.results.sunset
                            }

                            // format store the display text
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .none
                            dateFormatter.timeStyle = .short
                            dateFormatter.locale = Locale(identifier: "en_GB")
                            dateFormatter.timeZone = TimeZone(abbreviation: "CET")
                            
                            var day: String = "today"
                            if Calendar.current.isDateInTomorrow(response.results.sunset) {
                                day = "tomrrow"
                            }
                            let sunsetTime = dateFormatter.string(from: response.results.sunset)
                            DispatchQueue.main.async {
                                nextSunset.text = "Next sunset is at \(sunsetTime) \(day)"
                            }
                            
                        }
                    } catch {
                        debugPrint(error)
                    }
                }
            }
            task.resume()
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

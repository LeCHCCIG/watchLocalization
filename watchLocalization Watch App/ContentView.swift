//
//  ContentView.swift
//  watchLocalization Watch App
//
//  Created by Kehinde  Elelu on 3/15/24.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var direction: Int?
    @State private var equipmentType: String?
    @State private var isHapticPlaying: Bool = false
    @State private var hapticTimer: Timer?
    @State private var designTypeNumber: Int?
    
    var body: some View {
        ZStack {
            if designTypeNumber == 1 {
                Color.red // Set background color to white
            }
            VStack {
                if equipmentType == "mobile" {
                    
                    // Design 1
                    if let direction = direction {
                        Text("DOA value: \(direction)")
                    } else {
                        Text("Fetching data...")
                    }
                    
                    // Button("Stop Haptic") {
                    //    stopHapticFeedback()
                    // }
                } else {
                    Text("Safe Environment")
                }
            }
            .padding()
        }
        .onAppear {
            // Call fetchData() when the view appears
            self.fetchData()
        }
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
            // Call fetchData() every 10 second
            self.fetchData()
        }
    }


    func fetchData() {
        guard let url = URL(string: "http://192.168.1.88:5300/direction") else {
            print("Invalid URL")
            return
        }
        
        let urlConfig = URLSessionConfiguration.default
        urlConfig.allowsCellularAccess = true

        URLSession(configuration: urlConfig).dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error -: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }

            if httpResponse.statusCode == 200 {
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        print("API Response: \(json)")
                        
                        if let equipmentType = (json as? [String: Any])?["equipmentType"] as? String {
                            DispatchQueue.main.async {
                                self.equipmentType = equipmentType
                                if equipmentType == "mobile" {
                                    self.startHapticFeedback()
                                } else {
                                    self.stopHapticFeedback()
                                }
                            }
                        }
                        
                        if let direction = (json as? [String: Any])?["direction"] as? Int {
                            DispatchQueue.main.async {
                                self.direction = direction
                            }
                        }
                    } catch {
                        print("Error parsing JSON: \(error.localizedDescription)")
                    }
                } else {
                    print("No data received")
                }
            } else {
                print("HTTP Error: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    func startHapticFeedback() {
        isHapticPlaying = true
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let device = WKInterfaceDevice.current()
            device.play(.notification) // Use .click or any other WKHapticType you prefer
        }
    }
    
    func stopHapticFeedback() {
        isHapticPlaying = false
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

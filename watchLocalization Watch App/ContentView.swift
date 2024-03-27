//
//  ContentView.swift
//  watchLocalization Watch App
//
//  Created by Kehinde  Elelu on 3/15/24.
//

import SwiftUI
import WatchKit
import AVFoundation

struct ContentView: View {
    @State private var direction: Int?
    @State private var equipmentType: String?
    @State private var designTypeNumber: Int?
    let timer = Timer.publish(every: 100, on: .main, in: .common).autoconnect()
    @State private var DOAvisualType: String = "arrowHeadAndText"
    
    //Haptic
    @State private var isHapticPlaying: Bool = false
    @State private var hapticTimer: Timer?

    // LED
    @State private var backgroundColor = Color.orange
    @State private var isLEDPlaying: Bool = false
    
    //Beeping
    @State private var isBeepPlaying: Bool = false
    @State private var beepTimer: Timer?
    let beepSoundURL = Bundle.main.url(forResource: "beep", withExtension: "mp3")
    
    
    var body: some View {
        ZStack {
            
            if DOAvisualType == "Text" {
                displayText()
                // LED
//                startLEDFeedback(color: backgroundColor)
            } else if DOAvisualType == "arrowHead" {
                CircleWithDividers(fetchData: fetchData, direction: $direction)
                    .frame(width: 200, height: 200)
            } else if DOAvisualType == "arrowHeadAndText" {
                displayText()
                    .offset(CGSize(width: 0, height: -110.0))
                CircleWithDividers(fetchData: fetchData, direction: $direction)
                    .frame(width: 200, height: 200)
            }

            VStack {
//                if equipmentType == "mobile" {
//                    displayText()
//                } else {
//                    Text("Safe Environment")
//                        .foregroundColor(.black)
//                }
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
    
    func displayText() -> Text {
        if let direction = direction {
            return Text("DOA value: \(direction)")
                        .font(.system(size: 13))
        } else {
            return Text("Fetching data....")
                        .font(.system(size: 13))
        }
    }

    func displayArrowhead() {
        return
    }
    
    
    //   Beeping ==========================================================
    // start beep
    func startBeepingFeedback() {
        isBeepPlaying = true
        var audioPlayer: AVAudioPlayer?

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: beepSoundURL!)
            guard let player = audioPlayer else { return }
            player.prepareToPlay()
            player.play()
        } catch let error {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    // stop beep
    func stopBeepingFeedback(){
        isBeepPlaying = false
    }
    //   Beeping ==========================================================
    
    
    //   LED ==========================================================
    // start LED
    func startLEDFeedback(color: Color) -> some View {
        isLEDPlaying = true
        return color
            .edgesIgnoringSafeArea(.all)
            .onReceive(timer) { _ in
                // Toggle between red and another color (e.g., blue)
                self.backgroundColor = (self.backgroundColor == Color.green) ? Color.blue : Color.yellow
            }
    }
    
    // stop LED
    func stopLEDFeedback() {
        isLEDPlaying = false
    }
    //   LED ==========================================================
    
    
    //   HAPTIC ==========================================================
    // Start haptic
    func startHapticFeedback() {
        isHapticPlaying = true
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let device = WKInterfaceDevice.current()
            device.play(.notification) // Use .click or any other WKHapticType you prefer
        }
    }
    
    // Stop haptic
    func stopHapticFeedback() {
        isHapticPlaying = false
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
    //   HAPTIC ==========================================================
}

struct CircleWithDividers: View {
    var fetchData: () -> Void
    @Binding var direction: Int?
    
    var circumference: CGFloat = 110

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black, lineWidth: 0.4)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .opacity(0.2)
                )
                .frame(width: circumference, height: circumference) // Set frame to control the circumference

            ForEach(0..<12) { index in
                let angle = Double(index) * (360.0 / 12)
                Divider(angle: angle)
                    .overlay(
                        Arrow(angle: Double(360 - (direction ?? 0)), color: .red)
                            .offset(x: 0, y: 0) // Offset to position the arrow at the bottom of the circle
                    )
//                    .frame(width: 110, height: 110)
                Text("\(Int(angle))°")
                    .font(.system(size: 13))
                    .position(x: 100 + 70 * cos(Angle(degrees: -angle).radians),
                              y: 100 + 70 * sin(Angle(degrees: -angle).radians))
            }
        }
        .onAppear {
            self.fetchData()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            self.fetchData()
        }
    }
}


struct Divider: View {
    let angle: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 100, y: 100))
            path.addLine(to: CGPoint(x: 100, y: 45))
        }
        .stroke(Color.black, lineWidth: 0.5)
        .rotationEffect(Angle(degrees: angle))
    }
}


struct Arrow: View {
    let angle: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let arrowLength = geometry.size.width / 2 - 45
            let arrowHeadLength: CGFloat = 15

            let endPoint = CGPoint(
                x: geometry.size.width / 2 + arrowLength * CGFloat(cos(Angle(degrees: angle).radians)),
                y: geometry.size.height / 2 + arrowLength * CGFloat(sin(Angle(degrees: angle).radians))
            )

            ZStack {
                Path { path in
                    // Starting from the center (0, 0)
                    path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                    // Extending outward based on the angle
                    path.addLine(to: endPoint)

                    // Adding arrowhead
                    path.move(to: endPoint)
                    path.addLine(to: CGPoint(
                        x: endPoint.x - arrowHeadLength * CGFloat(cos(Angle(degrees: angle + 30).radians)),
                        y: endPoint.y - arrowHeadLength * CGFloat(sin(Angle(degrees: angle + 30).radians))
                    ))

                    path.move(to: endPoint)
                    path.addLine(to: CGPoint(
                        x: endPoint.x - arrowHeadLength * CGFloat(cos(Angle(degrees: angle - 30).radians)),
                        y: endPoint.y - arrowHeadLength * CGFloat(sin(Angle(degrees: angle - 30).radians))
                    ))
                }
                .stroke(color, lineWidth: 2)
            }
        }
        .aspectRatio(contentMode: .fit)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

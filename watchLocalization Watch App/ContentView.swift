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
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var DOAvisualType: String = "None"
    
    //Haptic
    @State private var isHapticPlaying: Bool = false
    @State private var hapticTimer: Timer?

    // LED
    @State private var backgroundColor = Color.orange
    @State private var isLEDPlaying: Bool = false
    @State private var currentIndex = 0
    
    //Beeping
    @State private var isBeepPlaying: Bool = false
    @State private var beepTimer: Timer?
    let beepSoundURL = Bundle.main.url(forResource: "beep", withExtension: "mp3")
    @State private var selectedCondition: String? = nil
    @State private var showButton = true
    @State private var hapticState = true
    
    var body: some View {
        ZStack {
            VStack() {
                if showButton {
                    VStack(spacing: 5) {
                        Button(action: {
                            selectedCondition = "Text"
                            // Hide the button
                            showButton.toggle()
                        }) {
                            Text("Text")
                        }
                        Button(action: {
                            selectedCondition = "ArrowHead"
                            // Hide the button
                            showButton.toggle()
                        }) {
                            Text("ArrowHead")
                        }
                        Button(action: {
                            selectedCondition = "ArrowHeadAndText"
                            // Hide the button
                            showButton.toggle()
                        }) {
                            Text("ArrowHead-Text")
                        }
                        Button(action: {
                            selectedCondition = "LED"
                            // Hide the button
                            showButton.toggle()
                        }) {
                            Text("LED")
                        }
                    }
                } else {
                    if selectedCondition != "LED" {
                        Button(action: {
                            isHapticPlaying = false
                            WKInterfaceDevice.current().play(.stop)
                            // Hide the button
                            showButton.toggle()
                            selectedCondition = "None"
                        }) {
                            Text("Go-Back")
                        }
                        if selectedCondition == "Text" && equipmentType == "mobile" {
                            // VIEW
                            displayText(fontSizeWeight: 20)
                            //VIEW
                            
                            startHapticFeedback()
                            
                        } else if selectedCondition == "ArrowHead" && equipmentType == "mobile" {
                            // VIEW
                            CircleWithDividers(fetchData: fetchData, direction: $direction)
                                .frame(width: 200, height: 200)
                            // VIEW
                            
//                            startHapticFeedback()
                            
                        } else if selectedCondition == "ArrowHeadAndText" && equipmentType == "mobile" {
                            // VIEW
                            displayText(fontSizeWeight: 14)
    //                            .offset(CGSize(width: 0, height: -110.0))
                            CircleWithDividers(fetchData: fetchData, direction: $direction)
                                .frame(width: 200, height: 200)
                            // VIEW
                            
//                            startHapticFeedback()
                        }
                    } else if selectedCondition == "LED" && equipmentType == "mobile" {
                        VStack(spacing: 5) {
                            // LED
                            startLEDFeedback(color: backgroundColor)
                            // LED
                            startHapticFeedback()
                            
                            Button(action: {
                                isHapticPlaying = false
                                WKInterfaceDevice.current().play(.stop)
                                // Hide the button
                                showButton.toggle()
                                selectedCondition = "None"
                            }) {
                                Text("Go-Back")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Call fetchData() when the view appears
            self.fetchData()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Call fetchData() every 10 second
            self.fetchData()
        }
    }


    func fetchData() {
        guard let url = URL(string: "http://192.168.1.145:5300/direction") else {
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
                        
                        if let equipmentType = (json as? [String: Any])?["model_type"] as? String {
                            DispatchQueue.main.async {
                                self.equipmentType = equipmentType
                            }
                        }
                        
                        if let direction = (json as? [String: Any])?["doa_value"] as? Int {
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
    
    func displayText(fontSizeWeight: CGFloat) -> Text {
        if let direction = direction {
            return Text("DOA value: \(direction)")
                        .font(.system(size: fontSizeWeight))
        } else {
            return Text("Fetching data....")
                        .font(.system(size: fontSizeWeight))
        }
    }

    
    //   Beeping ==========================================================
    // start beep
    func startBeepingFeedback() -> some View {
        isBeepPlaying = true
        WKInterfaceDevice.current().play(.click)
//        var audioPlayer: AVAudioPlayer?
//
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: beepSoundURL!)
//            guard let player = audioPlayer else { return EmptyView() }
//            player.prepareToPlay()
//            player.play()
//        } catch let error {
//            print("Error playing sound: \(error.localizedDescription)")
//        }
        return EmptyView()
    }
    
    // stop beep
    func stopBeepingFeedback() -> some View {
        isBeepPlaying = false
        return EmptyView()
    }
    //   Beeping ==========================================================
    
    
    //   LED ==========================================================
    // start LED
    func startLEDFeedback(color: Color) -> some View {
        isLEDPlaying = true // Assuming isLEDPlaying is a @State variable to control the state of LED playing
        
        let colors: [Color] = [.red, .green, .blue, .yellow] // Define the colors to cycle through
        
        return color
            .edgesIgnoringSafeArea(.all)
            .onReceive(timer) { _ in
                // Increment current index and loop back to 0 if it reaches the end
                self.currentIndex = (self.currentIndex + 1) % colors.count
                self.backgroundColor = colors[self.currentIndex]
            }
    }
    
    // stop LED
    func stopLEDFeedback() -> some View {
        isLEDPlaying = false
        return EmptyView()
    }
    //   LED ==========================================================
    
    
    //   HAPTIC ==========================================================
    // Start haptic
    func startHapticFeedback() -> some View {
        isHapticPlaying = true
        let device = WKInterfaceDevice.current()
        device.play(.notification)
        return EmptyView()
    }
    
    // Stop haptic
    func stopHapticFeedback() -> some View {
        isHapticPlaying = false
        WKInterfaceDevice.current().play(.stop)
        return EmptyView()
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

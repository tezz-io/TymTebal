//
//  TimeTableItemContent.swift
//  TymTebal
//
//  Created by Tejas M R on 22/11/20.
//

import SwiftUI
import Combine

struct TimeTableItemContent: View {
    @State var selected: String
    @State var title: String
    @State var hour: String
    @State var min: String
    
    var daysDict = [
        "Sun" : 1,
        "Mon" : 2,
        "Tue" : 3,
        "Wed" : 4,
        "Thu" : 5,
        "Fri" : 6,
        "Sat" : 7
    ]
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentation
    
    @State var item: FetchedResults<TimeTableItem>.Element
    
    var body: some View {
        
        VStack {
            DaysMenu(color: Color.blue, selected: $selected)
                .padding(.vertical, 15)
            
            

            
            HStack(spacing: 5) {
                Text("Time: ")
                    .frame(width: 50, alignment: .leading)
                TextField("00 (Hour)", text: $hour)
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 2)
                    )
                    .onReceive(Just(hour)) { val in
                        let filtered = val.filter {
                            "0123456789".contains($0)
                        }
                        if filtered != val {
                            self.hour = filtered
                        }
                        self.hour = String(self.hour.prefix(2))
                        if (stringToInt(self.hour) >= 24) {
                            self.hour = "23"
                        }
                    }
                
                TextField("00 (Min)", text: $min)
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 2)
                    )
                    .onReceive(Just(min)) { val in
                        let filtered = val.filter {
                            "0123456789".contains($0)
                        }
                        if filtered != val {
                            self.min = filtered
                        }
                        self.min = String(self.min.prefix(2))
                        if (stringToInt(self.min) >= 60) {
                            self.min = "59"
                        }
                    }
            }
            .padding()
            HStack(spacing: 5) {
                Text("Title: ")
                    .frame(width: 50, alignment: .leading)
                TextField("Enter title ", text: $title)
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 2)
                    )
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                self.presentation.wrappedValue.dismiss()
                updateItem(item)
            }) {
                Image(systemName: "square.and.arrow.down")
                    .resizable()
                    .font(.system(.title))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 13)
                    .frame(width: 50, height: 50, alignment: .center)
                    .background(Color.black)
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
                    .padding(.bottom, 10)
            }
        }

    }
    
    func stringToInt(_ string: String) -> Int {
        var intValue = 0
        for i in string {
            intValue = intValue*10 + (Int(i.asciiValue ?? 0) - 48)*10
        }
        return intValue / 10
    }
    
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let error = error as NSError
            fatalError("Unresolved Error: \(error)")
        }
    }
    
    func updateItem(_ item: FetchedResults<TimeTableItem>.Element) {
        withAnimation {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [(item.uuid ?? UUID()).uuidString])

            item.title = title
            item.time = hour + ":" + min
            item.day = selected
            
            setNotification(uuid: item.uuid ?? UUID(), day: item.day ?? "Mon", time: item.time ?? "08:00", title: item.title ?? "Untitled", content: item.content ?? "")
            
            saveContext()
        }
    }
    
    func setNotification(uuid: UUID, day: String, time: String, title: String, content: String) {
        
        let center = UNUserNotificationCenter.current()
                
        center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = content
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        
        dateComponents.weekday = daysDict[day]
        
        let timeArr = time.split { $0 == ":" }
        dateComponents.hour = stringToInt(String(timeArr[0]))
        dateComponents.minute = stringToInt(String(timeArr[1]))
        print(dateComponents)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let uuidString = uuid.uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: notificationContent, trigger: trigger)
        
        
        
        center.add(request) { (error) in
            if error != nil {
                print(error?.localizedDescription ?? "No error")
            }
        }
    }
}


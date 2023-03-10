//
//  ContentView.swift
//  SwiftCal
//
//  Created by Thomas Prezioso Jr on 1/9/23.
//

import SwiftUI
import CoreData
import WidgetKit

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.date, ascending: true)],
        predicate: NSPredicate(format: "(date >= %@) AND (date <= %@)", Date().startOfCalendarWithPrefixDays as CVarArg, Date().endOfMonth as CVarArg),
        animation: .default)
    private var days: FetchedResults<Day>
    
    var body: some View {
        NavigationView {
            VStack {
                CalendarHeaderView()
                LazyVGrid(columns: Array (repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(days) { day in
                        if day.date!.monthInt != Date().monthInt {
                            Text("")
                        } else {
                            Text(day.date!.formatted(.dateTime.day()))
                                .fontWeight(.bold)
                                .foregroundColor(day.didStudy ? .orange : .secondary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background {
                                    Circle()
                                        .foregroundColor(.orange.opacity(day.didStudy ? 0.3 : 0.0))
                                }
                                .onTapGesture {
                                    if day.date!.dayInt <= Date().dayInt {
                                        day.didStudy.toggle()
                                        do {
                                            try viewContext.save()
                                            // reload widget data on successful user save
                                            WidgetCenter.shared.reloadTimelines(ofKind: "SwiftCalWidget")
                                            print("👆🏻 \(day.date!.dayInt) ")
                                        } catch {
                                            
                                        }
                                    } else {
                                        print("Can't tap into the future")
                                    }
                                }
                        }
                    }
                }
                Spacer()
            }.navigationTitle(Date().formatted(.dateTime.month(.wide)))
            .padding()
            .onAppear {
                if days.isEmpty {
                    createMonthDays (for: .now.startOfPreviousMonth)
                    createMonthDays(for: .now)
                } else if days.count < 10 { // Is this ONLY the prefix days
                    createMonthDays(for: .now)
                }
            }
        }
    }
    
    func createMonthDays(for date: Date) {
        for dayOffset in 0..<date.numberOfDaysInMonth {
            let newDay = Day(context: viewContext)
            newDay.date = Calendar.current.date(byAdding: .day, value: dayOffset, to: date.startOfMonth)
            newDay.didStudy = false
        }
        do {
           try viewContext.save()
            print("✅ \(date.monthFullName) days created")
        } catch {
            print("failed to save context")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

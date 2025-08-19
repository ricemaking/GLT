import Foundation
import SwiftUI
import CoreData

public struct DownloadEmpTimesheetView1: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var curEmployee: Int32
    @Binding var loginID: String?

    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    
    @State private var selectedEmployeeIDs: Set<Int32> = []
    @State private var csvURLs: [URL] = []
    @State private var showingExporter = false
    @State private var selectedMonth: Int16 = Int16(Calendar.current.component(.month, from: Date()))
    @State private var selectedYear: Int16 = Int16(Calendar.current.component(.year, from: Date()))

    public var body: some View {
        VStack {
            HStack {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text("\(Calendar.current.monthSymbols[month - 1])").tag(Int16(month))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)

                Picker("Year", selection: $selectedYear) {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    ForEach((currentYear-5)...(currentYear+1), id: \.self) { year in
                        Text("\(year)").tag(Int16(year))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
            }

            List {
                ForEach(employees.filter {
                    $0.nameFirst?.isEmpty == false && $0.nameLast?.isEmpty == false
                }, id: \.self) { employee in
                    let isSelected = selectedEmployeeIDs.contains(employee.id)
                    Button(action: {
                        if isSelected {
                            selectedEmployeeIDs.remove(employee.id)
                        } else {
                            selectedEmployeeIDs.insert(employee.id)
                        }
                    }) {
                        HStack {
                            Text("\(employee.nameLast ?? "No Last Name"), \(employee.nameFirst ?? "No First Name")")
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(isSelected ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                }
            }

            Button("Download Timesheets") {
                csvURLs = selectedEmployeeIDs.compactMap { id in
                    csvURLForEmployee(id: id)
                }
                if !csvURLs.isEmpty {
                    showingExporter = true
                }
            }
            .disabled(selectedEmployeeIDs.isEmpty)
            .padding()
        }
        // change this to send emails
        .sheet(isPresented: $showingExporter) {
            if #available(iOS 16.0, *) {
                ShareLink(items: csvURLs) {
                    Label("Export CSVs", systemImage: "square.and.arrow.up")
                        .padding()
                }
            } else { // for ios 15 and below
                ActivityView(activityItems: csvURLs)
            }
        }
    }

    private func csvURLForEmployee(id: Int32) -> URL? {
        let fileName = "Timesheet_\(id)_\(selectedMonth)_\(selectedYear).csv"
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = docsDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }
        return nil
    }
}

#if !os(macOS)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

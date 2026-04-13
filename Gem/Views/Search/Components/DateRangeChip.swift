import SwiftUI
import Foundation

import SwiftUI

struct DateTimeRangeChip: View {
    @State private var isDatePickerPresented: Bool = .init()
    @State private var date: Date = .init()
    
    let selected: Bool
    let label: String
    
    init(selected: Bool, label: String) {
        self.selected = selected
        self.label = label
    }
    
    var body: some View {
        if selected {
            Button {
                onTap()
            } label: {
                Text(label)
            }
            .tint(.orange)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
            .sheet(isPresented: $isDatePickerPresented) {
                DatePicker(selection: $date, in: ...Date()) {
                    Text("date picker")
                }
            }
        } else {
            Button {
                onTap()
            } label: {
                Text(label)
            }
            .tint(.orange)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
            .sheet(isPresented: $isDatePickerPresented) {
                DatePicker(selection: $date, in: ...Date(), displayedComponents: [.date]) {
                    Text("date picker")
                }
            }
        }
    }
    
    func onTap() {
        isDatePickerPresented = true
    }
}

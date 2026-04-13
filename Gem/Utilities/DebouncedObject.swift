import Combine
import SwiftUI

public final class DebounceObject: ObservableObject {
    @Published var text: String = String()
    @Published var debouncedText: String = String()
    private var bag = Set<AnyCancellable>()
    
    public init(dueTime: TimeInterval = 1) {
        $text
            .removeDuplicates()
            .debounce(for: .seconds(dueTime), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.debouncedText = value
            })
            .store(in: &bag)
    }
}

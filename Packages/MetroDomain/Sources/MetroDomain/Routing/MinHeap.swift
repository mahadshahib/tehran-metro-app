import Foundation

/// A small binary min-heap priority queue for Dijkstra. Kept internal and simple
/// — the routing graph has only a few hundred nodes.
struct MinHeap<Element: Hashable> {
    private struct Entry { let element: Element; let priority: Double }
    private var storage: [Entry] = []

    var isEmpty: Bool { storage.isEmpty }

    mutating func push(_ element: Element, priority: Double) {
        storage.append(Entry(element: element, priority: priority))
        siftUp(from: storage.count - 1)
    }

    mutating func pop() -> (Element, Double)? {
        guard !storage.isEmpty else { return nil }
        storage.swapAt(0, storage.count - 1)
        let entry = storage.removeLast()
        if !storage.isEmpty { siftDown(from: 0) }
        return (entry.element, entry.priority)
    }

    private mutating func siftUp(from index: Int) {
        var child = index
        var parent = (child - 1) / 2
        while child > 0 && storage[child].priority < storage[parent].priority {
            storage.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(from index: Int) {
        var parent = index
        let count = storage.count
        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var candidate = parent
            if left < count && storage[left].priority < storage[candidate].priority { candidate = left }
            if right < count && storage[right].priority < storage[candidate].priority { candidate = right }
            if candidate == parent { return }
            storage.swapAt(parent, candidate)
            parent = candidate
        }
    }
}

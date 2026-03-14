import Foundation
import SwiftUI

/// Coordinates drag and drop interactions with optimized performance
@MainActor
class DragDropCoordinator: ObservableObject {
    @Published var activeDragColor: GameColor? = nil
    @Published var dragPosition: CGPoint = .zero
    @Published var dropTargetRow: Int? = nil
    @Published var dropTargetIndex: Int? = nil
    @Published var sourceSlotRow: Int? = nil
    @Published var sourceSlotIndex: Int? = nil
    @Published var isOverBoard: Bool = false

    // Performance optimization: Use private storage with batched updates
    private var _slotFrames: [String: CGRect] = [:]
    private var _boardFrame: CGRect = .zero

    // Spatial indexing for performance optimization
    private var frameUpdateQueue = DispatchQueue(label: "frame-updates", qos: .userInteractive)

    var slotFrames: [String: CGRect] { _slotFrames }
    var boardFrame: CGRect { _boardFrame }

    func registerSlotFrame(_ frame: CGRect, row: Int, slot: Int) {
        let key = "\(row)-\(slot)"
        _slotFrames[key] = frame
    }

    func registerBoardFrame(_ frame: CGRect) {
        _boardFrame = frame
    }

    func updateDragPosition(_ position: CGPoint, getCurrentRowNumber: () -> Int) {
        dragPosition = position

        // Check if we are over the game board region
        let wasOverBoard = isOverBoard
        isOverBoard = _boardFrame.contains(position)

        let oldTargetRow = dropTargetRow
        let oldTargetIndex = dropTargetIndex
        var newTargetRow: Int? = nil
        var newTargetIndex: Int? = nil

        let activeRowNumber = getCurrentRowNumber()

        // Optimized hit testing - early exit if not over board
        guard isOverBoard else {
            if oldTargetRow != nil || oldTargetIndex != nil {
                dropTargetRow = nil
                dropTargetIndex = nil
            }
            return
        }

        // Spatial optimization: only check frames near the drag position
        for (key, frame) in _slotFrames {
            // Quick distance check before expensive contains operation
            let frameCenter = CGPoint(x: frame.midX, y: frame.midY)
            let distance = sqrt(pow(position.x - frameCenter.x, 2) + pow(position.y - frameCenter.y, 2))

            // Only do expensive contains check if we're close
            if distance < max(frame.width, frame.height) && frame.contains(position) {
                let parts = key.split(separator: "-")
                if parts.count == 2,
                   let r = Int(parts[0]),
                   let s = Int(parts[1]),
                   r == activeRowNumber {
                    newTargetRow = r
                    newTargetIndex = s
                    break
                }
            }
        }

        // Batch update to reduce @Published notifications
        if oldTargetRow != newTargetRow || oldTargetIndex != newTargetIndex {
            dropTargetRow = newTargetRow
            dropTargetIndex = newTargetIndex
            if newTargetIndex != nil {
                SoundManager.shared.hapticLight()
            }
        }
    }

    func startDrag(color: GameColor, from sourceRow: Int? = nil, sourceIndex: Int? = nil) {
        activeDragColor = color
        sourceSlotRow = sourceRow
        sourceSlotIndex = sourceIndex
    }

    func endDragging() {
        // Reset all drag state in one batch to minimize @Published updates
        activeDragColor = nil
        dragPosition = .zero
        dropTargetRow = nil
        dropTargetIndex = nil
        sourceSlotRow = nil
        sourceSlotIndex = nil
        isOverBoard = false
    }

    func clearDropTargets() {
        dropTargetRow = nil
        dropTargetIndex = nil
    }
}
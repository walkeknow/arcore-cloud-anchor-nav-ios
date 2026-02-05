//
// Copyright 2024 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import RealityKit
import simd
import UIKit

/// Renders thick lines with directional arrows between 3D points in AR.
class LineRenderer {
  private var lineEntities: [ModelEntity] = []
  private var arrowEntities: [ModelEntity] = []
  private let parentEntity: Entity
  
  // Visual parameters matching Android implementation
  private let lineColor = UIColor(red: 0.55, green: 0.25, blue: 0.75, alpha: 0.4)
  private let arrowColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
  private let lineWidth: Float = 0.15  // meters - width of the line
  private let lineHeight: Float = 0.01  // meters - very thin to appear flat
  private let arrowSpacing: Float = 0.4  // meters between arrows
  private let arrowWidth: Float = 0.12  // chevron width - wider
  private let arrowLength: Float = 0.20  // chevron length - longer
  private let arrowThickness: Float = 0.08  // arrow line thickness - thicker
  private let arrowHeight: Float = 0.01  // arrow height - very thin to appear flat
  private let arrowVerticalOffset: Float = 0.005  // lift arrows above line
  
  init(parent: Entity) {
    self.parentEntity = parent
  }
  
  /// Updates the lines to connect the given 3D points.
  func updateLines(points: [SIMD3<Float>]) {
    // Clear existing lines and arrows
    clearLines()
    
    guard points.count >= 2 else { return }
    
    // Create all line segments first
    for i in 0..<points.count - 1 {
      let p1 = points[i]
      let p2 = points[i + 1]
      createLineSegment(from: p1, to: p2)
    }
    
    // Then create arrows on top
    for i in 0..<points.count - 1 {
      let p1 = points[i]
      let p2 = points[i + 1]
      createArrowsAlongSegment(from: p1, to: p2)
    }
  }
  
  /// Clears all rendered lines and arrows.
  func clearLines() {
    for entity in lineEntities {
      entity.removeFromParent()
    }
    lineEntities.removeAll()
    
    for entity in arrowEntities {
      entity.removeFromParent()
    }
    arrowEntities.removeAll()
  }
  
  private func createLineSegment(from p1: SIMD3<Float>, to p2: SIMD3<Float>) {
    let direction = p2 - p1
    let length = simd_length(direction)
    
    guard length > 0.001 else { return }
    
    // Create a flat rectangular mesh for the line
    let mesh = MeshResource.generateBox(
      width: lineWidth,
      height: lineHeight,
      depth: length
    )
    
    var material = UnlitMaterial()
    material.color = .init(tint: lineColor)
    
    let lineEntity = ModelEntity(mesh: mesh, materials: [material])
    
    // Position and orient the line
    let midpoint = (p1 + p2) / 2
    lineEntity.position = midpoint
    
    // Calculate rotation to align with direction
    let normalizedDir = simd_normalize(direction)
    let defaultForward = SIMD3<Float>(0, 0, 1)
    
    // Calculate rotation quaternion
    if abs(simd_dot(normalizedDir, defaultForward) + 1.0) < 0.001 {
      // Vectors are opposite, rotate 180 degrees around Y
      lineEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
    } else {
      let axis = simd_cross(defaultForward, normalizedDir)
      let angle = acos(simd_dot(defaultForward, normalizedDir))
      if simd_length(axis) > 0.001 {
        lineEntity.orientation = simd_quatf(angle: angle, axis: simd_normalize(axis))
      }
    }
    
    parentEntity.addChild(lineEntity)
    lineEntities.append(lineEntity)
  }
  
  private func createArrowsAlongSegment(from p1: SIMD3<Float>, to p2: SIMD3<Float>) {
    let direction = p2 - p1
    let segmentLength = simd_length(direction)
    
    guard segmentLength > 0.01 else { return }
    
    let normalizedDir = simd_normalize(direction)
    
    // Calculate perpendicular vector for chevron shape
    let up = SIMD3<Float>(0, 1, 0)
    var right = simd_cross(normalizedDir, up)
    
    if simd_length(right) < 0.01 {
      // Direction parallel to up, use different perpendicular
      let altUp = SIMD3<Float>(1, 0, 0)
      right = simd_cross(normalizedDir, altUp)
    }
    
    if simd_length(right) > 0.01 {
      right = simd_normalize(right)
    }
    
    // Generate arrows at regular intervals
    let numArrows = max(1, Int(segmentLength / arrowSpacing))
    
    for i in 1...numArrows {
      let t = Float(i) / Float(numArrows + 1)
      let arrowCenter = p1 + direction * t
      
      createChevronArrow(
        at: arrowCenter,
        direction: normalizedDir,
        right: right
      )
    }
  }
  
  private func createChevronArrow(
    at center: SIMD3<Float>,
    direction: SIMD3<Float>,
    right: SIMD3<Float>
  ) {
    // Lift the arrow slightly above the line to prevent z-fighting
    let up = SIMD3<Float>(0, 1, 0)
    let liftedCenter = center + up * arrowVerticalOffset
    
    // Project direction and right onto horizontal plane for flat arrows
    let flatDirection = simd_normalize(SIMD3<Float>(direction.x, 0, direction.z))
    let flatRight = simd_normalize(SIMD3<Float>(right.x, 0, right.z))
    
    // Chevron tip (pointing forward in direction of motion) - shared point for both arms
    let tip = liftedCenter + flatDirection * arrowLength * 0.5
    
    // Back center point
    let backCenter = liftedCenter - flatDirection * arrowLength * 0.5
    
    // Left arm back point
    let leftBack = backCenter - flatRight * arrowWidth
    
    // Right arm back point  
    let rightBack = backCenter + flatRight * arrowWidth
    
    // Create left arm (from left back to tip)
    createArrowArm(from: leftBack, to: tip)
    
    // Create right arm (from right back to tip)
    createArrowArm(from: rightBack, to: tip)
  }
  
  private func createArrowArm(from p1: SIMD3<Float>, to p2: SIMD3<Float>) {
    let direction = p2 - p1
    let length = simd_length(direction)
    
    guard length > 0.001 else { return }
    
    // Create a flat thin rectangle for the arrow arm (thin in Y, wide in X, long in Z)
    let mesh = MeshResource.generateBox(
      width: arrowThickness,
      height: arrowHeight,
      depth: length
    )
    
    var material = UnlitMaterial()
    material.color = .init(tint: arrowColor)
    
    let arrowEntity = ModelEntity(mesh: mesh, materials: [material])
    
    // Position at midpoint
    let midpoint = (p1 + p2) / 2
    arrowEntity.position = midpoint
    
    // Orient along the arm direction in the horizontal plane
    let normalizedDir = simd_normalize(direction)
    
    // Project direction onto horizontal plane (XZ) to keep arrow flat
    let horizontalDir = simd_normalize(SIMD3<Float>(normalizedDir.x, 0, normalizedDir.z))
    
    // Calculate rotation around Y axis only to keep arrows flat/horizontal
    let angle = atan2(horizontalDir.x, horizontalDir.z)
    arrowEntity.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
    
    parentEntity.addChild(arrowEntity)
    arrowEntities.append(arrowEntity)
  }
}

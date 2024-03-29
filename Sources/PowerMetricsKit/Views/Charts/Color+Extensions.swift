//
//  Color+Extensions.swift
//
//
//  Created by Raúl Montón Pinillos on 10/2/24.
//

import Foundation
import SwiftUI

extension Color {
    static var randomChartColor: Color {
        return Color(
            hue: Double.random(in: 0..<1),
            saturation: 0.8,
            brightness: 0.8
        )
    }
    
    static func newChartColor(existing: [Color], environment: EnvironmentValues) -> Color {
        var hues = [Float]()
        for color in existing {
            let resolvedColor = color.resolve(in: environment)
            let red = resolvedColor.red
            let green = resolvedColor.green
            let blue = resolvedColor.blue
            let hue = Self.rgbToHue(r: red, g: green, b: blue)
            hues.append(hue)
        }
        if hues.isEmpty {
            return .blue
        }
        hues = hues.sorted()
        
        // Find the biggest distance between two hues
        var maxDistance: Float = .zero
        var hueA: Float = .zero
        var hueB: Float = .zero
        for index in 0..<hues.count {
            let distance: Float
            if (index + 1) == hues.count {
                distance = (360.0 - hues[index]) + hues[0]
                if distance > maxDistance {
                    maxDistance = distance
                    hueA = hues[index]
                    hueB = hues[0]
                }
            } else{
                distance = hues[index + 1] - hues[index]
                if distance > maxDistance {
                    maxDistance = distance
                    hueA = hues[index]
                    hueB = hues[index + 1]
                }
            }
        }
        
        // Find the midpoint
        let finalHue: Float
        if hueB > hueA {
            finalHue = (hueB + hueA)/2.0
        } else if hueB == hueA {
            finalHue = (hueA + 180).truncatingRemainder(dividingBy: 360)
        } else {
            let tempHue = (hueA + (360 + hueB))/2.0
            if tempHue > 360 {
                finalHue = tempHue - 360
            } else {
                finalHue = tempHue
            }
        }
        
        return Color(hue: Double(finalHue / 360), saturation: 0.8, brightness: 0.8)
    }
    
    static private func rgbToHue(r: Float, g: Float, b: Float) -> Float {
        let r = r/255
        let g = g/255
        let b = b/255
        guard let max = [r, g, b].max() else { return .zero }
        guard let min = [r, g, b].min() else { return .zero }
        let c = max - min
        var hue: Float
        if (c == 0) {
            hue = 0
        } else {
            switch(max) {
            case r:
                let segment = (g - b) / c
                var shift: Float = 0 / 60       // R° / (360° / hex sides)
                if (segment < 0) {          // hue > 180, full rotation
                    shift = 360 / 60         // R° / (360° / hex sides)
                }
                hue = segment + shift
                break
            case g:
                let segment = (b - r) / c
                let shift: Float = 120 / 60     // G° / (360° / hex sides)
                hue = segment + shift
                break
            case b:
                let segment = (r - g) / c
                let shift: Float = 240 / 60     // B° / (360° / hex sides)
                hue = segment + shift
                break
            default:
                return .zero
            }
        }
        return hue * 60 // hue is in [0,6], scale it up
      }
}

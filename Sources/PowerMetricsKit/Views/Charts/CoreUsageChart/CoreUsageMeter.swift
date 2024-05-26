//
//  CoreUsageMeter.swift
//  
//
//  Created by Raúl Montón Pinillos on 21/4/24.
//

import SwiftUI

struct CoreUsageMeter: View {
    
    let usage: Double
    let coreType: CoreType?
    
    let numberOfLevels: Int
    let spacing: CGFloat
    
    init(usage: Double, coreType: CoreType?, numberOfLevels: Int = 20, spacing: CGFloat = 1.0) {
        self.usage = usage
        self.coreType = coreType
        self.numberOfLevels = numberOfLevels
        self.spacing = spacing
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: spacing) {
                ForEach(0..<numberOfLevels) { level in
                    Rectangle()
                        .foregroundStyle(levelColor(for: level))
                }
            }
            if let coreType {
                Text("\(coreType.shortName)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.leading, 1)
            }
        }
        .padding(spacing)
        .background(.black)
    }
    
    func levelColor(for level: Int) -> Color {
        if (Double(numberOfLevels - level) /  Double(numberOfLevels)) <= usage {
            return .green
        } else {
            return .clear
        }
    }
}
